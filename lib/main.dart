// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/zaytouna_park.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase before the app starts
  await Supabase.initialize(
    url: 'https://qmxuvlftxgoqtkotrtkh.supabase.co',
    anonKey: 'sb_publishable_RMcETbUFV93edmrW4P6VVQ_MRPUJbQE',
  );

  // Load saved user session before showing UI
  await RouteGuard.initialize();

  runApp(
    const ZaytounaPark(),
  ); // Removed appRouter parameter since it's not needed
}
