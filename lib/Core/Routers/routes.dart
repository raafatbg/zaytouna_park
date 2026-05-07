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
  static const String pos = '/pos'; // The Kiosk/Quick Sale view

  // SPORTS & FACILITIES (Zaytouna Park Specific)
  static const String bookings = '/bookings'; // Football & Padel Calendar
  static const String playground = '/playground'; // Kids Zone Entry/Passes
  static const String tables = '/tables'; // Restaurant Floor Plan

  // INVENTORY & MENU
  static const String inventory = '/inventory';
  static const String categories = '/categories';
  static const String suppliers = '/suppliers';
  static const String menuItems = '/menu-items'; // Products & Matte Kits

  // SALES & ORDERS
  static const String orders = '/orders';
  static const String salesReport = '/sales-report';
  static const String reports = '/reports';
  static const String deletedOrders = '/deleted-orders';

  // FINANCE & CUSTOMERS
  static const String customers = '/customers';
  static const String expenses = '/expenses';

  // SETTINGS
  static const String settings = '/settings';
  static const String profile = '/profile';

  // ERROR
  static const String notFound = '/not-found';

  // HELPER METHODS
  static bool isAuthRoute(String route) {
    return route == login || route == forgotPassword;
  }

  static String getDisplayName(String route) {
    const Map<String, String> names = {
      adminDashboard: 'Admin Dashboard',
      cashierDashboard: 'Cashier Dashboard',
      kitchenDashboard: 'Kitchen Dashboard',
      home: 'Dashboard',
      pos: 'Point of Sale',
      bookings: 'Sports Bookings',
      playground: 'Playground',
      tables: 'Restaurant Tables',
      inventory: 'Stock Control',
      orders: 'Order History',
      customers: 'Customer Loyalty',
      expenses: 'Expenses & Bills',
      settings: 'Settings',
    };
    return names[route] ?? 'Zaytouna Park';
  }

  static IconData getIcon(String route) {
    const Map<String, IconData> icons = {
      adminDashboard: Icons.admin_panel_settings,
      cashierDashboard: Icons.point_of_sale,
      kitchenDashboard: Icons.kitchen,
      home: Icons.dashboard_rounded,
      pos: Icons.point_of_sale_rounded,
      bookings: Icons.sports_tennis_rounded, // Padel/Football icon
      playground: Icons.child_friendly_rounded,
      tables: Icons.table_restaurant_rounded,
      inventory: Icons.inventory_rounded,
      orders: Icons.receipt_long_rounded,
      customers: Icons.people_rounded,
      expenses: Icons.monetization_on_rounded,
      settings: Icons.settings_rounded,
    };
    return icons[route] ?? Icons.circle_outlined;
  }

  // Sidebar navigation items
  static const List<String> mainNavigation = [
    home,
    pos,
    bookings,
    playground,
    tables,
    inventory,
    orders,
    customers,
    expenses,
    settings,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// APP PERMISSIONS (Tailored for Zaytouna Park logic)
// ─────────────────────────────────────────────────────────────────────────────

class AppPermissions {
  AppPermissions._();

  // Basic POS
  static const String useTerminal = 'use_terminal';
  static const String voidOrders = 'void_orders';

  // Sports & Facilities
  static const String manageBookings =
      'manage_bookings'; // Can book Football/Padel
  static const String manageFacilities =
      'manage_facilities'; // Can open/close fields

  // F&B
  static const String refillMatte = 'refill_matte'; // Specific waiter action

  // Back Office
  static const String viewReports = 'view_reports';
  static const String manageInventory = 'manage_inventory';
  static const String manageExpenses = 'manage_expenses';
  static const String manageStaff = 'manage_staff';

  /// Returns the permission required to access a specific route
  static String? requiredFor(String route) {
    switch (route) {
      case Routes.pos:
        return useTerminal;
      case Routes.bookings:
        return manageBookings;
      case Routes.playground:
        return useTerminal;
      case Routes.inventory:
        return manageInventory;

      case Routes.salesReport:
      case Routes.reports:
        return viewReports;
      case Routes.expenses:
        return manageExpenses;
      case Routes.settings:
        return manageStaff; // Only admins/managers see settings
      default:
        return null; // Publicly accessible to all logged-in staff
    }
  }
}
