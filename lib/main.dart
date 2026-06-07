// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/zaytouna_park.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read environment variables baked directly into the compiled JavaScript binary
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Guard check to make sure variables are present during compilation
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    assert(
      false,
      "Missing Supabase environment variables! Ensure you build with the --dart-define-from-file flag.",
    );
  }

  // Initialize Supabase natively before the app starts
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Load saved user session before showing UI
  await RouteGuard.initialize();

  runApp(const ZaytounaPark());
}
