import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../state/app_state.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final passConfirmCtrl = TextEditingController();
  bool obscurePass = true;
  String? localError;

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final username = userCtrl.text.trim();
    final pass = passCtrl.text.trim();
    setState(() => localError = null);
    state.sessionErrorMessage = null;

    if (username.isEmpty || pass.isEmpty) return;

    if (!isLogin) {
      final confirm = passConfirmCtrl.text.trim();
      if (!AppConfig.usernamePattern.hasMatch(username)) {
        setState(() => localError = 'شناسه فقط می‌تواند شامل حروف انگلیسی، عدد و _ باشد (۳ تا ۲۰ کاراکتر)');
        return;
      }
      if (pass.length < AppConfig.minPasswordLength) {
        setState(() => localError = 'رمز عبور باید حداقل ${AppConfig.minPasswordLength} کاراکتر باشد');
        return;
      }
      if (pass.toLowerCase() == username.toLowerCase()) {
        setState(() => localError = 'رمز عبور نمی‌تواند با شناسه‌ی کاربری یکسان باشد');
        return;
      }
      if (pass != confirm) {
        setState(() => localError = 'رمز عبور و تکرار آن یکسان نیستند');
        return;
      }
    }

    final ok = isLogin
        ? await state.login(username, pass)
        : await state.signup(username, pass);

    if (!ok && isLogin && state.authError != null && state.authError!.contains('یافت نشد')) {
      setState(() => isLogin = false);
      passCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final error = localError ?? state.authError ?? state.sessionErrorMessage;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.line),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 20)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (rect) => AppColors.accentGradient.createShader(rect),
                      child: Text(
                        isLogin ? 'ورود' : 'ساخت حساب جدید',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: userCtrl,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(hintText: 'شناسه کاربری'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passCtrl,
                      obscureText: obscurePass,
                      textAlign: TextAlign.right,
                      onSubmitted: (_) { if (isLogin) _submit(); },
                      decoration: InputDecoration(
                        hintText: 'رمز عبور',
                        suffixIcon: IconButton(
                          icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.muted, size: 20),
                          onPressed: () => setState(() => obscurePass = !obscurePass),
                        ),
                      ),
                    ),
                    if (!isLogin) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: passConfirmCtrl,
                        obscureText: obscurePass,
                        textAlign: TextAlign.right,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(hintText: 'تکرار رمز عبور'),
                      ),
                    ],
                    if (error != null && error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.red, fontSize: 13)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: state.authBusy ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: state.authBusy
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(isLogin ? 'ورود' : 'ثبت‌نام'),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        isLogin = !isLogin;
                        localError = null;
                      }),
                      child: Text(isLogin ? 'حساب ندارید؟ ثبت‌نام کنید' : 'قبلاً ثبت‌نام کرده‌اید؟ وارد شوید'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
