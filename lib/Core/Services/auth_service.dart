// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

// RENAME: Changed to AppAuthException to prevent collision with Supabase's native AuthException
class AppAuthException implements Exception {
  final String message;
  AppAuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final _supabase = Supabase.instance.client;

  /// Staff Login (email/password via Supabase Auth)
  /// Returns: {'success': bool, 'user': AuthUser, 'staff': StaffData, 'role': String}
  Future<Map<String, dynamic>> staffLogin(String email, String password) async {
    try {
      // Step 1: Authenticate with Supabase Auth
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (authResponse.user == null) {
        throw AppAuthException(
          'Authentication failed. Please check your credentials.',
        );
      }

      // Step 2: Get staff details from database using the secure Auth UID
      // using maybeSingle() instead of returning a list and getting [0]
      final staff = await _supabase
          .from('staff')
          .select('*, roles(name, description)')
          .eq('id', authResponse.user!.id)
          .maybeSingle();

      if (staff == null) {
        // Sign out if staff record doesn't exist in the public schema
        await _supabase.auth.signOut();
        throw AppAuthException(
          'Staff record not found. Contact your administrator.',
        );
      }

      // Step 3: Check if staff is active
      if (staff['is_active'] != true) {
        await _supabase.auth.signOut();
        throw AppAuthException(
          'This account is inactive. Contact your administrator.',
        );
      }

      // Step 4: Extract role (safely handling map or list from join)
      final roleData = staff['roles'];
      String roleName = 'cashier';

      if (roleData is Map) {
        roleName = roleData['name'] ?? 'cashier';
      } else if (roleData is List && roleData.isNotEmpty) {
        roleName = roleData.first['name'] ?? 'cashier';
      }

      // Validate role - Expanded to match the roles used in your RouteGuard
      final validRoles = [
        'admin',
        'manager',
        'cashier',
        'kitchen',
        'chef',
        'waiter',
      ];
      if (!validRoles.contains(roleName.toLowerCase())) {
        await _supabase.auth.signOut();
        throw AppAuthException(
          'Invalid staff role configuration. Contact your administrator.',
        );
      }

      return {
        'success': true,
        'user': authResponse.user,
        'staff': staff,
        'role': roleName.toLowerCase(),
        'staffId': staff['id'],
        'staffName': staff['name'] ?? 'Staff Member',
      };
    } on AuthException catch (e) {
      // This specifically catches Supabase's native authentication errors (e.g. wrong password)
      throw AppAuthException(e.message);
    } catch (e) {
      if (e is AppAuthException) rethrow; // Pass our custom exceptions through
      throw AppAuthException('Login failed: ${e.toString()}');
    }
  }

  /// Customer Login (phone number, creates customer if not exists)
  Future<Map<String, dynamic>> customerLogin(String name, String phone) async {
    try {
      name = name.trim();
      phone = phone.trim();

      if (name.isEmpty || phone.isEmpty) {
        throw AppAuthException('Name and phone are required');
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
      throw AppAuthException('Customer login failed: ${e.toString()}');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AppAuthException('Logout failed: ${e.toString()}');
    }
  }

  /// Get current staff user details
  Future<Map<String, dynamic>?> getCurrentStaffUser() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return null;

      // Use the secure UID instead of email string matching
      final staff = await _supabase
          .from('staff')
          .select('*, roles(name)')
          .eq('id', authUser.id)
          .maybeSingle();

      if (staff == null) return null;

      final roleData = staff['roles'];
      String roleName = 'cashier';

      if (roleData is Map) {
        roleName = roleData['name'] ?? 'cashier';
      } else if (roleData is List && roleData.isNotEmpty) {
        roleName = roleData.first['name'] ?? 'cashier';
      }

      return {...staff, 'role': roleName.toLowerCase()};
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
      throw AppAuthException('Failed to fetch roles: ${e.toString()}');
    }
  }
}
