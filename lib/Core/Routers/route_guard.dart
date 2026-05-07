// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final List<String> permissions;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.permissions = const [],
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
}

class RouteGuard {
  /// Result object for login attempts
  static Future<_LoginResult> login(String email, String password) async {
    try {
      final response = await _instance._supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user == null) {
        return _LoginResult(success: false, message: 'Invalid credentials.');
      }

      // Refresh session/profile and WAIT for it to complete
      await _instance._checkSession();

      // If profile is still null, they authenticated but aren't in the staff table
      if (_instance._profile == null) {
        await _instance._supabase.auth.signOut();
        return _LoginResult(
          success: false,
          message: 'Staff record not found or account inactive.',
        );
      }

      return _LoginResult(success: true);
    } catch (e) {
      return _LoginResult(success: false, message: e.toString());
    }
  }

  static final RouteGuard _instance = RouteGuard._internal();
  factory RouteGuard() => _instance;
  RouteGuard._internal();

  UserProfile? _profile;
  final SupabaseClient _supabase = Supabase.instance.client;
  final _authStateController = StreamController<UserProfile?>.broadcast();

  Stream<UserProfile?> get authStateStream => _authStateController.stream;

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

      if (data != null && data['is_active'] != false) {
        final roleData = data['roles'];
        String roleName = 'cashier';

        // Safely parse Supabase join data (can return Map or List depending on relationship)
        if (roleData is Map) {
          roleName = roleData['name'] ?? 'cashier';
        } else if (roleData is List && roleData.isNotEmpty) {
          roleName = roleData.first['name'] ?? 'cashier';
        }

        _profile = UserProfile(
          id: data['id'].toString(),
          email: data['email'] ?? session.user.email ?? '',
          fullName: data['name'] ?? 'Staff Member',
          role: roleName,
          permissions: _getPermissions(roleName),
        );
        _authStateController.add(_profile);
      } else {
        _profile = null;
        _authStateController.add(null);
      }
    } catch (e) {
      developer.log('Profile Load Error: $e');
      _profile = null;
      _authStateController.add(null);
    }
  }

  List<String> _getPermissions(String role) {
    if (role.toLowerCase() == 'admin') return ['all'];
    return ['standard'];
  }

  // --- STATIC HELPERS (Fixes Settings.dart errors) ---
  static UserProfile? get user => _instance._profile;
  static bool get isAuthenticated => _instance._profile != null;
  static String? getCurrentUserName() => _instance._profile?.fullName;
  static String? getCurrentUserEmail() => _instance._profile?.email;
  static String? getCurrentUserRole() => _instance._profile?.role;

  static Future<void> logout() async =>
      await _instance._supabase.auth.signOut();
}

/// Simple result class for login attempts
class _LoginResult {
  final bool success;
  final String? message;
  _LoginResult({required this.success, this.message});
}
