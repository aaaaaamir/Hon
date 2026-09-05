import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'error_overlay.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  // به‌جای جعبه‌ی خاکستری پیش‌فرض برای خطاهای build یه ویجت،
  // فقط یه آیکون کوچیک قرمز نشون بده؛ متن کامل خطا + stack trace
  // میره تو بنر بالای صفحه
  ErrorWidget.builder = (FlutterErrorDetails details) {
    reportGlobalError(
      '${details.exceptionAsString()}\n\n--- STACK TRACE ---\n${details.stack}',
    );
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      color: const Color(0x11FF0000),
      child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
    );
  };

  // خطاهای فریم‌ورک (build / layout / paint) رو می‌گیره
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    reportGlobalError(
      '${details.exceptionAsString()}\n\n--- STACK TRACE ---\n${details.stack}',
    );
  };

  runZonedGuarded(() {
    runApp(const HonChatApp());
  }, (error, stack) {
    // خطاهای async که فریم‌ورک به‌تنهایی نمی‌گیرتشون
    reportGlobalError('$error\n\n--- STACK TRACE ---\n$stack');
  });
}

class HonChatApp extends StatelessWidget {
  const HonChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'چت',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: ErrorBannerOverlay(child: child ?? const SizedBox.shrink()),
        ),
        home: const _RootGate(),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    switch (state.authStatus) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.loggedOut:
        return const AuthScreen();
      case AuthStatus.loggedIn:
        return const HomeScreen();
    }
  }
}
