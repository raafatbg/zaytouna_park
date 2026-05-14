
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zaytouna_park/Core/Routers/app_routers.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';

class ZaytounaPark extends StatelessWidget {
  const ZaytounaPark({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        Size currentDesignSize;
        if (screenWidth >= 1024) {
          currentDesignSize = const Size(1440, 900);
        } else if (screenWidth >= 600) {
          currentDesignSize = const Size(768, 1024);
        } else {
          currentDesignSize = const Size(375, 812);
        }

        return ScreenUtilInit(
          designSize: currentDesignSize,
          minTextAdapt: true,
          splitScreenMode: true,
          useInheritedMediaQuery: true,
          builder: (context, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Zaytouna Park POS',
              theme: _buildThemeData(),
              darkTheme: _buildDarkThemeData(),
              themeMode: ThemeMode.system,
              initialRoute: _getInitialRoute(),
              onGenerateRoute: AppRouter().generateRoute,
              onUnknownRoute: (settings) {
                return AppRouter().generateRoute(
                  RouteSettings(
                    name: Routes.notFound,
                    arguments: settings.name,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _getInitialRoute() {
    if (RouteGuard.isAuthenticated) {
      final user = RouteGuard.user;
      if (user != null) {
        switch (user.role.toLowerCase()) {
          case 'admin':
            return Routes.adminDashboard;
          case 'cashier':
            return Routes.cashierDashboard;
          case 'kitchen':
          case 'chef':
            return Routes.kitchenDashboard;
          default:
            return Routes.cashierDashboard;
        }
      }
    }
    return Routes.login;
  }

  ThemeData _buildThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB8860B),
        primary: const Color(0xFFB8860B),
        secondary: const Color(0xFF8B6914),
        tertiary: Colors.amber,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB8860B),
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          elevation: 2,
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB8860B),
          side: const BorderSide(color: Color(0xFFB8860B)),
          minimumSize: Size(double.infinity, 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFB8860B),
          textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFFB8860B),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFB8860B),
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      fontFamily: 'Poppins',
    );
  }

  ThemeData _buildDarkThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB8860B),
        primary: const Color(0xFFB8860B),
        secondary: const Color(0xFF8B6914),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.grey.shade900,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        color: Colors.grey.shade800,
      ),
    );
  }
}

extension ResponsiveHelper on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < 600;
  bool get isTablet =>
      MediaQuery.of(this).size.width >= 600 &&
      MediaQuery.of(this).size.width < 1024;
  bool get isDesktop => MediaQuery.of(this).size.width >= 1024;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}
