import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/app_user.dart';
import 'inventory_view.dart';
import 'treasury_view.dart';
import 'admin_home_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final theme = Theme.of(context);

    // Definir destinos según el rol
    List<BottomNavigationBarItem> destinations = [];
    List<Widget> views = [];

    if (user?.role == UserRole.administrador) {
      destinations = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Inventario'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Tesorería'),
      ];
      views = [
        AdminHomeView(onNavigate: _onNavigate),
        const InventoryView(),
        const TreasuryView(),
      ];
    } else if (user?.role == UserRole.tesorero) {
      destinations = const [
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Tesorería'),
      ];
      views = [
        const TreasuryView(),
      ];
      // Si _selectedIndex se sale del rango
      if (_selectedIndex >= views.length) _selectedIndex = 0;
    } else if (user?.role == UserRole.materiales) {
      destinations = const [
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Inventario'),
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
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                tooltip: themeProvider.isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Opciones de sesión',
            onSelected: (value) {
              if (value == 'logout') {
                auth.logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Text('Cerrar sesión', style: TextStyle(color: theme.colorScheme.error)),
                    ],
                  ),
                ),
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text('Hola, ${user?.name} 👋', style: theme.textTheme.titleSmall),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      body: views.isNotEmpty ? views[_selectedIndex] : const Center(child: Text('Sin acceso')),
      bottomNavigationBar: destinations.length > 1 ? BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavigate,
        items: destinations,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        backgroundColor: theme.colorScheme.surface,
        elevation: 8,
      ) : null,
    );
  }
}
