import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const HonChatApp());
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
          child: child!,
        ),
        home: const _RootGate(),
      ),
    );
  }
}

/// بر اساس وضعیت ورود کاربر، صفحه‌ی مناسب را نشان می‌دهد.
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
