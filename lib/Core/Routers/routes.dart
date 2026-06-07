// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

class Routes {
  Routes._();

  // AUTHENTICATION
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // ROLE DASHBOARDS
  static const String adminDashboard = '/admin-dashboard';
  static const String cashierDashboard = '/cashier-dashboard';
  static const String kitchenDashboard = '/kitchen-dashboard';

  // MAIN NAVIGATION
  static const String shell = '/shell';
  static const String home = '/home';
  static const String pos = '/pos';

  // SPORTS & FACILITIES
  static const String bookings = '/bookings';
  static const String playground = '/playground';
  static const String tables = '/tables';
  static const String manageTables = '/manage-tables';
  static const String facilities = '/facilities';
  static const String bookFacility = '/book-facility';
  static const String facilityBookings = '/facility-bookings';

  // INVENTORY & MENU
  static const String inventory = '/inventory';
  static const String categories = '/categories';
  static const String suppliers = '/suppliers';
  static const String menu = '/menu';

  // SALES & ORDERS
  static const String orders = '/orders';
  static const String sales = '/sales';
  static const String reports = '/reports';
  static const String salesReport = '/sales-report';

  // FINANCE & CUSTOMERS
  static const String customers = '/customers';
  static const String expenses = '/expenses';

  // SETTINGS
  static const String settings = '/settings';
  static const String profile = '/profile';

  // ERROR
  static const String notFound = '/not-found';

  // ─── HELPERS ──────────────────────────────────────────────────────
  static bool isAuthRoute(String route) =>
      route == login || route == forgotPassword;

  static String getDisplayName(String route) {
    const names = <String, String>{
      adminDashboard: 'Admin Dashboard',
      cashierDashboard: 'Cashier Dashboard',
      kitchenDashboard: 'Kitchen Dashboard',
      home: 'Dashboard',
      pos: 'Point of Sale',
      bookings: 'Sports Bookings',
      facilityBookings: 'Facility Bookings',
      playground: 'Playground',
      tables: 'Restaurant Tables',
      manageTables: 'Manage Tables',
      inventory: 'Inventory',
      orders: 'Order History',
      customers: 'Customer Loyalty',
      expenses: 'Expenses & Bills',
      settings: 'Settings',
      menu: 'Menu Management',
      facilities: 'Facilities',
      bookFacility: 'Book a Facility',
      sales: 'Sales',
      reports: 'Reports',
      salesReport: 'Sales Report',
      profile: 'Staff Profile',
    };
    return names[route] ?? 'Zaytouna Park';
  }

  static IconData getIcon(String route) {
    const icons = <String, IconData>{
      adminDashboard: Icons.admin_panel_settings,
      cashierDashboard: Icons.point_of_sale,
      kitchenDashboard: Icons.kitchen,
      home: Icons.dashboard_rounded,
      pos: Icons.point_of_sale_rounded,
      bookings: Icons.sports_tennis_rounded,
      playground: Icons.child_friendly_rounded,
      tables: Icons.table_restaurant_rounded,
      manageTables: Icons.table_restaurant_rounded,
      inventory: Icons.inventory_rounded,
      orders: Icons.receipt_long_rounded,
      customers: Icons.people_rounded,
      expenses: Icons.monetization_on_rounded,
      settings: Icons.settings_rounded,
      menu: Icons.restaurant_menu_rounded,
      facilities: Icons.apartment_rounded,
      bookFacility: Icons.event_available_rounded,
      facilityBookings: Icons.event_note_rounded,
      sales: Icons.attach_money_rounded,
      reports: Icons.bar_chart_rounded,
      salesReport: Icons.bar_chart_rounded,
      profile: Icons.person_pin_rounded,
    };
    return icons[route] ?? Icons.circle_outlined;
  }

  static const List<String> mainNavigation = <String>[
    home,
    pos,
    bookFacility,
    bookings,
    playground,
    tables,
    inventory,
    manageTables,
    orders,
    customers,
    expenses,
    settings,
  ];
}

// ─────────────────────────────────────────────────────────────────────
// APP PERMISSIONS
// ─────────────────────────────────────────────────────────────────────
class AppPermissions {
  AppPermissions._();

  // POS
  static const String useTerminal = 'use_terminal';
  static const String voidOrders = 'void_orders';

  // Sports & Facilities
  static const String createBookings = 'create_bookings';
  static const String manageBookings = 'manage_bookings';
  static const String manageFacilities = 'manage_facilities';

  // F&B
  static const String refillMatte = 'refill_matte';
  static const String manageTables = 'manage_tables';

  // Kitchen
  static const String viewKitchenDisplay = 'view_kitchen_display';
  static const String markItemsReady = 'mark_items_ready';

  // Back Office (admin-only)
  static const String viewReports = 'view_reports';
  static const String manageInventory = 'manage_inventory';
  static const String manageExpenses = 'manage_expenses';
  static const String manageStaff = 'manage_staff';

  /// Role → permissions map.
  /// Admins bypass all checks (handled in RouteGuard).
  static const Map<String, List<String>> rolePermissions = {
    'admin': [
      useTerminal,
      voidOrders,
      createBookings,
      manageBookings,
      manageFacilities,
      refillMatte,
      manageTables,
      viewKitchenDisplay,
      markItemsReady,
      viewReports,
      manageInventory,
      manageExpenses,
      manageStaff,
    ],
    'cashier': [
      useTerminal,
      createBookings,
      refillMatte,
      // ── Newly granted to cashiers ──
      // (sales, expenses, inventory, menu now open to cashiers)
    ],
    'kitchen': [viewKitchenDisplay, markItemsReady],
  };

  /// Returns the permission required to access a given route.
  /// Returns null if any authenticated user may access it.
  static String? requiredFor(String route) {
    switch (route) {
      // ── POS & core cashier screens ─────────────────────────────
      case Routes.pos:
        return useTerminal;

      case Routes.orders:
      case Routes.customers:
      case Routes.tables:
        return useTerminal;

      // ── NOW OPEN TO CASHIERS (useTerminal) ─────────────────────
      case Routes.sales:
      case Routes.salesReport:
        return useTerminal; // was: viewReports

      case Routes.expenses:
        return useTerminal; // was: manageExpenses

      case Routes.inventory:
      case Routes.categories:
      case Routes.suppliers:
        return useTerminal; // was: manageInventory

      case Routes.menu:
        return useTerminal; // was: manageInventory

      // ── Facilities ─────────────────────────────────────────────
      case Routes.bookings:
      case Routes.playground:
      case Routes.bookFacility:
      case Routes.facilityBookings:
        return createBookings;

      case Routes.facilities:
        return manageFacilities;

      // ── Restaurant ─────────────────────────────────────────────
      case Routes.manageTables:
        return manageTables;

      // ── Admin-only ─────────────────────────────────────────────
      case Routes.reports: // full analytics dashboard
        return viewReports;

      case Routes.settings:
        return manageStaff;

      case Routes.kitchenDashboard:
        return viewKitchenDisplay;

      // ── Open to any authenticated user ─────────────────────────
      // home, profile, shell
      default:
        return null;
    }
  }
}
