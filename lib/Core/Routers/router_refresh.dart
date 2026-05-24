import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';

/// Notifies GoRouter whenever auth state changes (signed in / out / token refresh).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream() {
    notifyListeners();
    _subscription = RouteGuard().authStateStream.listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
