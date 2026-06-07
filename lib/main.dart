// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/zaytouna_park.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing Supabase environment variables! '
      'Run with: flutter run --dart-flutter cleandefine-from-file=env.json',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await RouteGuard.initialize();

  runApp(const ZaytounaPark());
}
