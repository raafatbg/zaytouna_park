import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url:
          'https://qmxuvlftxgoqtkotrtkh.supabase.co', // From Supabase dashboard
      anonKey: 'sb_publishable_RMcETbUFV93edmrW4P6VVQ_MRPUJbQE',
    );
  }
}

final supabase = Supabase.instance.client;
