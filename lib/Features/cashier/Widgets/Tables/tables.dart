// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TablesPage extends StatefulWidget {
  const TablesPage({super.key});

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  // Get the Supabase client instance
  final _supabase = Supabase.instance.client;

  // Fetch tables from the database, ordered by name
  Future<List<Map<String, dynamic>>> _fetchTables() async {
    final response = await _supabase
        .from('restaurant_tables')
        .select()
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Floor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Force a rebuild to fetch fresh data
              setState(() {});
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchTables(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tables = snapshot.data ?? [];

          if (tables.isEmpty) {
            return const Center(child: Text('No tables found.'));
          }

          // A responsive grid that fits more columns on wider screens (tablets)
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200, // Max width of a table card
              childAspectRatio: 1.0, // Square cards
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              final isAvailable = table['is_available'] as bool;
              final name = table['name'] as String;
              final capacity = table['capacity'] as int?;

              return _buildTableCard(name, capacity, isAvailable);
            },
          );
        },
      ),
    );
  }

  Widget _buildTableCard(String name, int? capacity, bool isAvailable) {
    // Dynamic styling based on table availability
    final cardColor = isAvailable ? Colors.green.shade100 : Colors.red.shade100;
    final iconColor = isAvailable ? Colors.green.shade800 : Colors.red.shade800;
    final statusText = isAvailable ? 'Available' : 'Occupied';

    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tapped $name')));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.table_restaurant, size: 40, color: iconColor),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (capacity != null) ...[
                const SizedBox(height: 4),
                Text('Seats: $capacity', style: const TextStyle(fontSize: 14)),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
