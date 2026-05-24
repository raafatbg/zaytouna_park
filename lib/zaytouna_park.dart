import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zaytouna_park/Core/Routers/app_routers.dart';

class ZaytounaPark extends StatelessWidget {
  const ZaytounaPark({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1024, 768),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp.router(
        title: 'Zaytouna Park',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB8860B)),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
