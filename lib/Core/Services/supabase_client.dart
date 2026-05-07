import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientService {
  static final SupabaseClient supabase = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL', // Replace with your Supabase URL
      anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
    );
  }

  // Example method to get customers
  static Future<List<Map<String, dynamic>>> getCustomers() async {
    final response = await supabase.from('customers').select();
    return response;
  }

  // Add more methods as needed for CRUD operations
}
