// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final _supabase = Supabase.instance.client;

  /// Staff Login (email/password via Supabase Auth)
  /// Returns: {'user': AuthUser, 'staff': StaffData, 'role': 'admin'|'cashier'|'kitchen'}
  Future<Map<String, dynamic>> staffLogin(String email, String password) async {
    try {
      // Step 1: Authenticate with Supabase Auth
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (authResponse.user == null) {
        throw AuthException(
          'Authentication failed. Please check your credentials.',
        );
      }

      // Step 2: Get staff details from database
      final staffList = await _supabase
          .from('staff')
          .select('*, roles(name, description)')
          .eq('email', email.trim());

      if (staffList.isEmpty) {
        // Sign out if staff record doesn't exist
        await _supabase.auth.signOut();
        throw AuthException(
          'Staff record not found. Contact your administrator.',
        );
      }

      final staff = staffList[0];

      // Step 3: Check if staff is active
      if (staff['is_active'] != true) {
        await _supabase.auth.signOut();
        throw AuthException(
          'This account is inactive. Contact your administrator.',
        );
      }

      // Step 4: Extract role (safely handling map or list from join)
      final roleData = staff['roles'];
      String roleName = 'cashier';
      if (roleData is Map) {
        roleName = roleData['name'] ?? 'cashier';
      } else if (roleData is List && roleData.isNotEmpty) {
        roleName = roleData[0]['name'] ?? 'cashier';
      }

      // Validate role
      if (!['admin', 'cashier', 'kitchen'].contains(roleName)) {
        await _supabase.auth.signOut();
        throw AuthException('Invalid staff role. Contact your administrator.');
      }

      return {
        'success': true,
        'user': authResponse.user,
        'staff': staff,
        'role': roleName,
        'staffId': staff['id'],
        'staffName': staff['name'],
      };
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      if (e.statusCode == '400') {
        throw AuthException('Invalid email or password.');
      } else if (e.statusCode == '401') {
        throw AuthException('Unauthorized. Please check your credentials.');
      } else {
        throw AuthException('Authentication error: ${e.message}');
      }
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  /// Customer Login (phone number, creates customer if not exists)
  Future<Map<String, dynamic>> customerLogin(String name, String phone) async {
    try {
      name = name.trim();
      phone = phone.trim();

      if (name.isEmpty || phone.isEmpty) {
        throw AuthException('Name and phone are required');
      }

      // Check if customer already exists
      final existing = await _supabase
          .from('customers')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      if (existing != null) {
        return {
          'success': true,
          'customer': existing,
          'isNewCustomer': false,
          'customerId': existing['id'],
        };
      }

      // Create new customer
      final newCustomer = await _supabase
          .from('customers')
          .insert({'name': name, 'phone': phone})
          .select()
          .single();

      return {
        'success': true,
        'customer': newCustomer,
        'isNewCustomer': true,
        'customerId': newCustomer['id'],
      };
    } catch (e) {
      throw AuthException('Customer login failed: ${e.toString()}');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Logout failed: ${e.toString()}');
    }
  }

  /// Get current staff user details
  Future<Map<String, dynamic>?> getCurrentStaffUser() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return null;

      final staffList = await _supabase
          .from('staff')
          .select('*, roles(name)')
          .eq('email', authUser.email!);

      if (staffList.isEmpty) return null;

      final staff = staffList[0];
      final roleData = staff['roles'];
      String roleName = 'cashier';
      if (roleData is Map) {
        roleName = roleData['name'] ?? 'cashier';
      } else if (roleData is List && roleData.isNotEmpty) {
        roleName = roleData[0]['name'] ?? 'cashier';
      }

      return {...staff, 'role': roleName};
    } catch (e) {
      print('Error getting current staff user: $e');
      return null;
    }
  }

  /// Check if staff is authenticated
  bool isStaffLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  /// Get all roles for dropdowns/selection
  Future<List<Map<String, dynamic>>> getAllRoles() async {
    try {
      return await _supabase.from('roles').select();
    } catch (e) {
      throw AuthException('Failed to fetch roles: ${e.toString()}');
    }
  }
}
