import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zaytouna_park/Core/Models/app_routers.dart';
import 'package:zaytouna_park/Core/Models/routes.dart';

class ZaytounaPark extends StatelessWidget {
  final AppRouter appRouter;
  const ZaytounaPark({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 2. Determine the current screen width
        final double screenWidth = constraints.maxWidth;

        // 3. Define our responsive breakpoints
        Size currentDesignSize;
        if (screenWidth >= 1024) {
          // LAPTOP / DESKTOP (e.g., standard 1440x900 monitor)
          currentDesignSize = const Size(1440, 900);
        } else if (screenWidth >= 600) {
          // TABLET (e.g., iPad Portrait 768x1024)
          currentDesignSize = const Size(768, 1024);
        } else {
          // MOBILE (e.g., standard iPhone 375x812)
          currentDesignSize = const Size(375, 812);
        }

        // 4. Pass the calculated design size into ScreenUtil
        return ScreenUtilInit(
          designSize: currentDesignSize,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Zaytouna Park POS',
              theme: _buildThemeData(),
              initialRoute: Routes.shell,
              onGenerateRoute: appRouter.generateRoute,
            );
          },
        );
      },
    );
  }

  ThemeData _buildThemeData() {
    return ThemeData(
      primarySwatch: Colors.red, // Updated to match our new theme!
      scaffoldBackgroundColor: Colors.white,
    );
  }
}
