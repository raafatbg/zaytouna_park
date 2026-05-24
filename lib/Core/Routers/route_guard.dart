// ignore_for_file: library_private_types_in_public_api
import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final Set<String> permissions;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.permissions = const <String>{},
  });

  bool get isAdmin =>
      role.toLowerCase() == 'admin' ||
      role.toLowerCase() == 'manager' ||
      permissions.contains('all');
}

class RouteGuard {
  static final RouteGuard _instance = RouteGuard._internal();
  factory RouteGuard() => _instance;
  RouteGuard._internal();

  UserProfile? _profile;
  final SupabaseClient _supabase = Supabase.instance.client;
  final _authStateController = StreamController<UserProfile?>.broadcast();

  Stream<UserProfile?> get authStateStream => _authStateController.stream;

  // ─── INIT ──────────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    await _instance._checkSession();
    _instance._supabase.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        await _instance._checkSession();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _instance._profile = null;
        _instance._authStateController.add(null);
      }
    });
  }

  /// Call from app shutdown if you ever tear down the singleton in tests.
  static void dispose() {
    _instance._authStateController.close();
  }

  // ─── LOGIN ─────────────────────────────────────────────────────────────────
  static Future<LoginResult> login(String email, String password) async {
    try {
      final response = await _instance._supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return LoginResult(success: false, message: 'Invalid credentials.');
      }

      await _instance._checkSession();

      if (_instance._profile == null) {
        await _instance._supabase.auth.signOut();
        return LoginResult(
          success: false,
          message: 'Staff record not found or account inactive.',
        );
      }

      return LoginResult(success: true);
    } catch (e) {
      return LoginResult(success: false, message: _mapAuthError(e));
    }
  }

  static Future<void> logout() async => _instance._supabase.auth.signOut();

  // ─── SESSION ───────────────────────────────────────────────────────────────
  Future<void> _checkSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      _profile = null;
      _authStateController.add(null);
      return;
    }

    try {
      final data = await _supabase
          .from('staff')
          .select('*, roles(name)')
          .eq('id', session.user.id)
          .maybeSingle();

      if (data == null || data['is_active'] == false) {
        _profile = null;
        _authStateController.add(null);
        return;
      }

      // Supabase joins may return Map or List depending on relationship cardinality.
      final roleData = data['roles'];
      String roleName = 'cashier';
      if (roleData is Map) {
        roleName = (roleData['name'] as String?) ?? 'cashier';
      } else if (roleData is List && roleData.isNotEmpty) {
        roleName = (roleData.first['name'] as String?) ?? 'cashier';
      }

      _profile = UserProfile(
        id: data['id'].toString(),
        email: (data['email'] as String?) ?? session.user.email ?? '',
        fullName: (data['name'] as String?) ?? 'Staff Member',
        role: roleName,
        permissions: _getPermissions(roleName),
      );
      _authStateController.add(_profile);
    } catch (e) {
      developer.log('Profile Load Error: $e');
      _profile = null;
      _authStateController.add(null);
    }
  }

  /// 🔴 SECURITY: This is the source of truth for what each role can do.
  /// Move to a Supabase `role_permissions` table once the role model is stable.
  Set<String> _getPermissions(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'manager':
        return const {'all'};

      case 'cashier':
        return const {
          'use_terminal',
          'void_orders',
          'manage_tables',
          'refill_matte',
          'create_bookings',
        };

      case 'waiter':
        return const {'use_terminal', 'manage_tables', 'refill_matte'};

      case 'kitchen':
      case 'chef':
        return const {'view_kitchen_display', 'mark_items_ready'};

      default:
        return const <String>{};
    }
  }

  // ─── STATIC HELPERS ────────────────────────────────────────────────────────
  static UserProfile? get user => _instance._profile;
  static bool get isAuthenticated => _instance._profile != null;
  static String? getCurrentUserName() => _instance._profile?.fullName;
  static String? getCurrentUserEmail() => _instance._profile?.email;
  static String? getCurrentUserRole() => _instance._profile?.role;

  static bool hasPermission(String requiredPermission) {
    final profile = _instance._profile;
    if (profile == null) return false;
    if (profile.isAdmin) return true;
    return profile.permissions.contains(requiredPermission);
  }

  // ─── ERROR MAPPING ─────────────────────────────────────────────────────────
  static String _mapAuthError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Email or password is incorrect.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email first.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'No internet connection. Check your network and retry.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Wait a minute and try again.';
    }
    return 'Unable to sign in. Please try again.';
  }
}

/// Simple result class for login attempts
class LoginResult {
  final bool success;
  final String? message;
  LoginResult({required this.success, this.message});
}
