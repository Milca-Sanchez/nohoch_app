import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/app_user.dart';
import 'inventory_view.dart';
import 'treasury_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final theme = Theme.of(context);

    // Definir destinos según el rol
    List<NavigationRailDestination> destinations = [];
    List<Widget> views = [];

    if (user?.role == UserRole.administrador) {
      destinations = const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Inventario')),
        NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: Text('Tesorería')),
      ];
      views = [
        const Center(child: Text('Dashboard Principal (Resumen)')), // Placeholder para el home
        const InventoryView(),
        const TreasuryView(),
      ];
    } else if (user?.role == UserRole.tesorero) {
      destinations = const [
        NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: Text('Tesorería')),
      ];
      views = [
        const TreasuryView(),
      ];
      // Si _selectedIndex se sale del rango
      if (_selectedIndex >= views.length) _selectedIndex = 0;
    } else if (user?.role == UserRole.materiales) {
      destinations = const [
        NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Inventario')),
      ];
      views = [
        const InventoryView(),
      ];
      if (_selectedIndex >= views.length) _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nohoch', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text('Hola, ${user?.name}', style: theme.textTheme.titleSmall),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              auth.logout();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: views.isNotEmpty ? views[_selectedIndex] : const Center(child: Text('Sin acceso')),
          ),
        ],
      ),
    );
  }
}
