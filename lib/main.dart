import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zaytouna_park/Core/Models/app_routers.dart';
import 'package:zaytouna_park/firebase_options.dart';
import 'package:zaytouna_park/zaytouna_park.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ZaytounaPark(appRouter: AppRouter()));
}
