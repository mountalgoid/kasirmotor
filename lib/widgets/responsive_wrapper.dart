import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bengkel_pro/providers/workshop_provider.dart';
import 'package:bengkel_pro/providers/theme_provider.dart';
import 'package:bengkel_pro/pages/dashboard_page.dart';
import 'package:bengkel_pro/pages/inventory_page.dart';
import 'package:bengkel_pro/pages/cashier_page.dart';
import 'package:bengkel_pro/pages/transaction_history_page.dart';
import 'package:bengkel_pro/pages/settings_page.dart';
import 'package:bengkel_pro/pages/customer_page.dart';
import 'package:bengkel_pro/pages/service_management_page.dart';
import 'package:bengkel_pro/widgets/dashboard_home.dart';

class ResponsiveWrapper extends StatefulWidget {
  const ResponsiveWrapper({super.key});

  @override
  State<ResponsiveWrapper> createState() => _ResponsiveWrapperState();
}

class _ResponsiveWrapperState extends State<ResponsiveWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardHome(),
    const InventoryPage(),
    const ServiceManagementPage(),
    const CustomerPage(),
    const CashierPage(),
    const TransactionHistoryPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;
    final themeProvider = context.read<ThemeProvider>();

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: const Text('Ibrahim Part'),
              actions: [
                IconButton(
                  icon: Icon(themeProvider.themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
                  onPressed: () => themeProvider.toggleTheme(),
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.settings_suggest, size: 30, color: Colors.blue)),
                        SizedBox(height: 12),
                        Text('Ibrahim Part', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  _drawerItem(0, 'Dashboard', Icons.dashboard),
                  _drawerItem(1, 'Inventori', Icons.inventory_2),
                  _drawerItem(2, 'Jasa Servis', Icons.build),
                  _drawerItem(3, 'Pelanggan', Icons.people),
                  _drawerItem(4, 'Kasir', Icons.point_of_sale),
                  _drawerItem(5, 'Riwayat', Icons.history),
                  _drawerItem(6, 'Pengaturan', Icons.settings),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              extended: MediaQuery.of(context).size.width > 1200,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.motorcycle, color: Colors.white)),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Inventori')),
                NavigationRailDestination(icon: Icon(Icons.build_circle_outlined), selectedIcon: Icon(Icons.build_circle), label: Text('Jasa Servis')),
                NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Pelanggan')),
                NavigationRailDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: Text('Kasir')),
                NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('Riwayat')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Pengaturan')),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: IconButton(
                      icon: Icon(themeProvider.themeMode == ThemeMode.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                  ),
                ),
              ),
            ),
          if (!isMobile) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventori'),
                NavigationDestination(icon: Icon(Icons.build_circle_outlined), selectedIcon: Icon(Icons.build_circle), label: 'Jasa'),
                NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Pelanggan'),
                NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Kasir'),
              ],
            )
          : null,
    );
  }

  Widget _drawerItem(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}
