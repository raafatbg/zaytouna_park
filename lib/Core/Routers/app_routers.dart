// lib/Core/Routing/app_router.dart
// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:zaytouna_park/Core/Models/routes.dart';
import 'package:zaytouna_park/Features/Home/Shell/appshell.dart';
import 'package:zaytouna_park/Features/Home/Widgets/Terminal/terminalscreen.dart';
import 'package:zaytouna_park/Features/Login/loginScreen.dart';

class AppRouter {
  Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.login:
        return _fade(const LoginScreen());
      case Routes.shell:
        return _fade(const ShellScreen());
      case Routes.terminal:
        return _fade(POSScreen());
      default:
        return _errorRoute(settings.name);
    }
  }

  static PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 260),
  );

  static Route _errorRoute(String? name) => MaterialPageRoute(
    builder: (_) => Scaffold(
      body: Center(
        child: Text(
          'No route: $name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}
