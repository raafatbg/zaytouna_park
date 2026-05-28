import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/Core/Routers/router_refresh.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';

// Auth
import 'package:zaytouna_park/Features/Auth/pages/Login/staff_login_page.dart';

// Admin
import 'package:zaytouna_park/Features/admin/admin_shell/admin_shell.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Categories/categories.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Facilities/facilities.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Inventory/inventory.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Suppliers/suppliers.dart';

// Cashier
import 'package:zaytouna_park/Features/cashier/cash_home.dart';
import 'package:zaytouna_park/Features/cashier/Shell/appshell.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Analytics/analatics.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Customers/customers.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Expenses/expenses.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Facilities/facilities_booking_page.dart'; // 🆕
import 'package:zaytouna_park/Features/cashier/Widgets/Facilities/facility_bookings_list_page.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Orders/orders.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Sales/sales.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Settings/settings.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Tables/manage_tables_page.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Tables/tables.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Terminal/terminalscreen.dart';

// Kitchen
import 'package:zaytouna_park/Features/kitchen/home_kitchen.dart';
import 'package:zaytouna_park/Features/kitchen/widgets/menu%20mangement/menumanagementscreen.dart';

// Shared
import 'package:zaytouna_park/Features/shared/placeholder_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: Routes.login,
    refreshListenable: GoRouterRefreshStream(),
    debugLogDiagnostics: true,
    redirect: _redirect,
    errorBuilder: (context, state) =>
        _ErrorScreen(message: state.error?.toString()),
    routes: <RouteBase>[
      // ─── AUTH ────────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.login,
        pageBuilder: (c, s) => _fade(state: s, child: const LoginScreen()),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (c, s) => _fade(
          state: s,
          child: const PlaceholderScreen(
            title: 'Forgot Password',
            message: 'Password recovery coming soon.',
            icon: Icons.lock_reset_rounded,
          ),
        ),
      ),

      // ─── DASHBOARDS ──────────────────────────────────────────────────────
      GoRoute(
        path: Routes.adminDashboard,
        pageBuilder: (c, s) => _fade(state: s, child: AdminShellScreen()),
      ),
      GoRoute(
        path: Routes.cashierDashboard,
        pageBuilder: (c, s) =>
            _fade(state: s, child: const CashierShellScreen()),
      ),
      GoRoute(
        path: Routes.shell,
        pageBuilder: (c, s) =>
            _fade(state: s, child: const CashierShellScreen()),
      ),
      GoRoute(
        path: Routes.kitchenDashboard,
        pageBuilder: (c, s) => _fade(state: s, child: const KitchenScreen()),
      ),
      GoRoute(
        path: Routes.home,
        pageBuilder: (c, s) => _fade(
          state: s,
          child: Builder(
            builder: (ctx) => PremiumCashierHome(
              onLaunchTerminal: () => ctx.push(Routes.pos),
            ),
          ),
        ),
      ),

      // ─── POS ─────────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.pos,
        pageBuilder: (c, s) => _scale(state: s, child: const UpgradedPOS()),
      ),

      // ─── VENUE ───────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.bookings,
        pageBuilder: (c, s) => _slide(
          state: s,
          child: const PlaceholderScreen(
            title: 'Sports Bookings',
            message: 'Manage Football and Padel court schedules.',
            icon: Icons.sports_soccer_rounded,
          ),
        ),
      ),
      GoRoute(
        path: Routes.playground,
        pageBuilder: (c, s) => _slide(
          state: s,
          child: const PlaceholderScreen(
            title: 'Playground',
            message: 'Entry passes and Kids Zone management.',
            icon: Icons.child_care_rounded,
          ),
        ),
      ),
      GoRoute(
        path: Routes.tables,
        pageBuilder: (c, s) => _slide(state: s, child: const TablesPage()),
      ),
      GoRoute(
        path: Routes.manageTables,
        pageBuilder: (c, s) =>
            _slide(state: s, child: const ManageTablesPage()),
      ),
      GoRoute(
        path: Routes.facilities,
        pageBuilder: (c, s) =>
            _slide(state: s, child: const FacilitiesScreen()),
      ),

      // 🆕 BOOK A FACILITY (cashier-facing)
      GoRoute(
        path: Routes.bookFacility,
        pageBuilder: (c, s) =>
            _slide(state: s, child: const FacilitiesBookingPage()),
      ),
      GoRoute(
        path: Routes.facilityBookings,
        pageBuilder: (c, s) =>
            _slide(state: s, child: const FacilityBookingsListPage()),
      ),

      // ─── INVENTORY & BACK OFFICE ─────────────────────────────────────────
      GoRoute(
        path: Routes.inventory,
        pageBuilder: (c, s) => _slide(state: s, child: const InventoryScreen()),
      ),
      GoRoute(
        path: Routes.categories,
        pageBuilder: (c, s) => _slide(state: s, child: const CategoryScreen()),
      ),
      GoRoute(
        path: Routes.suppliers,
        pageBuilder: (c, s) => _slide(state: s, child: const SuppliersScreen()),
      ),
      GoRoute(
        path: Routes.menu,
        pageBuilder: (c, s) =>
            _slide(state: s, child: const MenuManagementScreen()),
      ),

      // ─── SALES & FINANCE ─────────────────────────────────────────────────
      GoRoute(
        path: Routes.orders,
        pageBuilder: (c, s) => _slide(state: s, child: const OrdersScreen()),
      ),
      GoRoute(
        path: Routes.sales,
        pageBuilder: (c, s) => _slide(state: s, child: const SalesScreen()),
      ),
      GoRoute(
        path: Routes.customers,
        pageBuilder: (c, s) => _slide(state: s, child: const CustomersScreen()),
      ),
      GoRoute(
        path: Routes.expenses,
        pageBuilder: (c, s) => _slide(state: s, child: const ExpensesScreen()),
      ),
      GoRoute(
        path: Routes.reports,
        pageBuilder: (c, s) => _slide(state: s, child: const AnalyticsScreen()),
      ),
      GoRoute(
        path: Routes.salesReport,
        pageBuilder: (c, s) => _slide(state: s, child: const AnalyticsScreen()),
      ),

      // ─── SYSTEM ──────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.settings,
        pageBuilder: (c, s) => _slide(state: s, child: const SettingsScreen()),
      ),
      GoRoute(
        path: Routes.profile,
        pageBuilder: (c, s) => _slide(
          state: s,
          child: const PlaceholderScreen(
            title: 'Staff Profile',
            icon: Icons.person_pin_rounded,
          ),
        ),
      ),

      // ─── ERROR ───────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.notFound,
        pageBuilder: (c, s) => _fade(
          state: s,
          child: const _ErrorScreen(message: 'Page not found'),
        ),
      ),
    ],
  );

  // ─── REDIRECT ──────────────────────────────────────────────────────────────
  static String? _redirect(BuildContext context, GoRouterState state) {
    final loggedIn = RouteGuard.isAuthenticated;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == Routes.login || loc == Routes.forgotPassword;

    if (!loggedIn && !isAuthRoute) return Routes.login;
    if (loggedIn && isAuthRoute) return _dashboardForCurrentRole();

    final required = AppPermissions.requiredFor(loc);
    if (required != null && !RouteGuard.hasPermission(required)) {
      return _dashboardForCurrentRole();
    }
    return null;
  }

  static String _dashboardForCurrentRole() {
    final user = RouteGuard.user;
    if (user == null) return Routes.login;
    switch (user.role.toLowerCase()) {
      case 'admin':
      case 'manager':
        return Routes.adminDashboard;
      case 'kitchen':
      case 'chef':
        return Routes.kitchenDashboard;
      default:
        return Routes.cashierDashboard;
    }
  }

  // ─── TRANSITIONS ───────────────────────────────────────────────────────────
  static Page<dynamic> _fade({
    required GoRouterState state,
    required Widget child,
  }) => CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, anim, _, c) =>
        FadeTransition(opacity: anim, child: c),
  );

  static Page<dynamic> _slide({
    required GoRouterState state,
    required Widget child,
  }) => CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, anim, _, c) {
      final offset = anim.drive(
        Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
      );
      return SlideTransition(position: offset, child: c);
    },
  );

  static Page<dynamic> _scale({
    required GoRouterState state,
    required Widget child,
  }) => CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, anim, _, c) {
      final scale = anim.drive(
        Tween(
          begin: 0.9,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.fastOutSlowIn)),
      );
      return ScaleTransition(
        scale: scale,
        child: FadeTransition(opacity: anim, child: c),
      );
    },
  );
}

class _ErrorScreen extends StatelessWidget {
  final String? message;
  const _ErrorScreen({this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message ?? 'Page not found',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(Routes.login),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
