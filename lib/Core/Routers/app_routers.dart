// ignore_for_file: file_names, unnecessary_underscores
import 'package:flutter/material.dart';

// --- CORE ---
import 'package:zaytouna_park/Core/Routers/routes.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';

// --- AUTHENTICATION ---
import 'package:zaytouna_park/Features/Auth/pages/Login/staff_login_page.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Categories/categories.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Facilities/facilities.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Inventory/inventory.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Suppliers/suppliers.dart';

// --- ADMIN SHELL ---
import 'package:zaytouna_park/Features/admin/admin_shell/admin_shell.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Settings/settings.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Tables/manage_tables_page.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Tables/tables.dart';

// --- DASHBOARDS ---
import 'package:zaytouna_park/Features/kitchen/home_kitchen.dart';
import 'package:zaytouna_park/Features/cashier/cash_home.dart';
import 'package:zaytouna_park/Features/cashier/Shell/appshell.dart';

// --- FEATURE SCREENS ---
import 'package:zaytouna_park/Features/cashier/Widgets/Terminal/terminalscreen.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Sales/sales.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Customers/customers.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Expenses/expenses.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Analytics/analatics.dart';
import 'package:zaytouna_park/Features/kitchen/widgets/menu%20mangement/menumanagementscreen.dart';
import 'package:zaytouna_park/Features/shared/placeholder_screen.dart';

// --- ADDED ---


class AppRouter {
  static final AppRouter _instance = AppRouter._internal();
  factory AppRouter() => _instance;
  AppRouter._internal();

  Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name;
    final arguments = settings.arguments;

    // WEB BUG FIX:
    if (routeName == '/' || routeName == '') {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) =>
            const Scaffold(backgroundColor: Colors.white),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }

    debugPrint('🚀 Navigation to: $routeName');

    // 1. Special handling for login route
    if (routeName == Routes.login) {
      if (RouteGuard.isAuthenticated) {
        return _redirectToDashboard();
      }
      return _fade(const LoginScreen(), settings);
    }

    // 2. Protect all other routes
    if (!RouteGuard.isAuthenticated) {
      debugPrint('⛔ Not authenticated, redirecting to login');
      return _redirectToLogin();
    }

    // Optional Security: Check if user has permission for this route
    final requiredPermission = AppPermissions.requiredFor(routeName ?? '');
    if (requiredPermission != null &&
        !RouteGuard.hasPermission(requiredPermission)) {
      debugPrint('⛔ Access Denied: User lacks $requiredPermission');
      return _errorRoute(
        'You do not have permission to access this page.',
        settings,
      );
    }

    // 3. Handle authenticated routes
    try {
      return _handleRoute(routeName, arguments, settings);
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      return _errorRoute('Navigation error: $e', settings);
    }
  }

  Route<dynamic> _handleRoute(
    String? routeName,
    Object? arguments,
    RouteSettings settings,
  ) {
    switch (routeName) {
      // ─── DASHBOARDS ────────────────────────────────────────────────────────
      case Routes.adminDashboard:
        return _fade(AdminShellScreen(), settings);

      case Routes.cashierDashboard:
      case Routes.shell:
        return _fade(const CashierShellScreen(), settings);

      case Routes.kitchenDashboard:
        return _fade(const KitchenScreen(), settings);

      case Routes.home:
        return _fade(
          Builder(
            builder: (context) => PremiumCashierHome(
              onLaunchTerminal: () =>
                  Navigator.of(context).pushNamed(Routes.pos),
            ),
          ),
          settings,
        );

      // ─── POS & KIOSK ───────────────────────────────────────────────────────
      case Routes.pos:
        return _scale(const UpgradedPOS(), settings);

      // ─── VENUE MANAGEMENT ──────────────────────────────────────────────────
      case Routes.bookings:
        return _slideRight(
          const PlaceholderScreen(
            title: 'Sports Bookings',
            message: 'Manage Football and Padel court schedules.',
            icon: Icons.sports_soccer_rounded,
          ),
          settings,
        );

      case Routes.playground:
        return _slideRight(
          const PlaceholderScreen(
            title: 'Playground',
            message: 'Entry passes and Kids Zone management.',
            icon: Icons.child_care_rounded,
          ),
          settings,
        );

      // FIX: Floor Plan is now pointing directly to TablesPage instead of PlaceholderScreen
      case Routes.tables:
        return _slideRight(const FloorPlanScreen(), settings);

      case Routes.manageTables:
        return _slideRight(const ManageTablesScreen(), settings);

      case Routes.facilities:
        return _slideRight(const FacilitiesScreen(), settings);

      // ─── INVENTORY & BACK OFFICE ───────────────────────────────────────────
      case Routes.inventory:
        return _slideRight(const InventoryScreen(), settings);

      case Routes.categories:
        return _slideRight(const CategoryScreen(), settings);

      case Routes.suppliers:
        return _slideRight(const SuppliersScreen(), settings);

      case Routes.menu:
        return _slideRight(const MenuManagementScreen(), settings);

      // ─── SALES & FINANCE ───────────────────────────────────────────────────
      case Routes.orders:
        return _slideRight(const SalesScreen(), settings);

      case Routes.sales:
        return _slideRight(
          const SalesScreen(),
          settings,
        );

      case Routes.customers:
        return _slideRight(const CustomersScreen(), settings);

      case Routes.expenses:
        return _slideRight(const ExpensesScreen(), settings);

      case Routes.reports:
      case Routes.salesReport:
        return _slideRight(const AnalyticsScreen(), settings);


      // ─── SYSTEM ────────────────────────────────────────────────────────────
      case Routes.settings:
        return _slideRight(
          const SettingsScreen(),
          settings,
        );

      case Routes.profile:
        return _slideRight(
          const PlaceholderScreen(
            title: 'Staff Profile',
            icon: Icons.person_pin_rounded,
          ),
          settings,
        );

      case Routes.notFound:
        return _errorRoute('Page not found', settings);

      default:
        return _errorRoute('Route $routeName not found', settings);
    }
  }

  // ─── REDIRECT HELPERS ──────────────────────────────────────────────────────

  Route<dynamic> _redirectToDashboard() {
    final user = RouteGuard.user;

    if (user == null) return _redirectToLogin();

    Widget targetPage;
    String targetRoute;

    switch (user.role.toLowerCase()) {
      case 'admin':
        targetPage = AdminShellScreen();
        targetRoute = Routes.adminDashboard;
        break;
      case 'kitchen':
      case 'chef':
        targetPage = const KitchenScreen();
        targetRoute = Routes.kitchenDashboard;
        break;
      case 'cashier':
      default:
        targetPage = const CashierShellScreen();
        targetRoute = Routes.cashierDashboard;
        break;
    }

    return PageRouteBuilder(
      settings: RouteSettings(name: targetRoute),
      pageBuilder: (_, __, ___) => targetPage,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  Route<dynamic> _redirectToLogin() {
    return PageRouteBuilder(
      settings: const RouteSettings(name: Routes.login),
      pageBuilder: (_, __, ___) => const LoginScreen(),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  Route<dynamic> _errorRoute(String message, RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(Routes.login, (route) => false),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── ANIMATIONS ────────────────────────────────────────────────────────────

  PageRouteBuilder _fade(Widget page, RouteSettings settings) =>
      PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  PageRouteBuilder _slideRight(Widget page, RouteSettings settings) =>
      PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) {
          final offset = anim.drive(
            Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          );
          return SlideTransition(position: offset, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      );

  PageRouteBuilder _scale(Widget page, RouteSettings settings) =>
      PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) {
          final scale = anim.drive(
            Tween(
              begin: 0.9,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.fastOutSlowIn)),
          );
          return ScaleTransition(
            scale: scale,
            child: FadeTransition(opacity: anim, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}

// ─── NAVIGATION EXTENSION ────────────────────────────────────────────────────
extension NavigationExtension on BuildContext {
  void pushNamed(String routeName, {Object? arguments}) {
    Navigator.pushNamed(this, routeName, arguments: arguments);
  }

  void pushReplacementNamed(String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(this, routeName, arguments: arguments);
  }

  void pushNamedAndRemoveUntil(String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      this,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  void popUntil(String routeName) {
    Navigator.popUntil(this, ModalRoute.withName(routeName));
  }

  bool canPop() => Navigator.canPop(this);

  void pop<T extends Object?>([T? result]) => Navigator.pop(this, result);
}
