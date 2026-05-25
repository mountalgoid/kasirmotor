import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workshop_provider.dart';
import '../models/transaction.dart';
import 'inventory_page.dart';
import 'cashier_page.dart';
import 'transaction_history_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardHome(),
    const InventoryPage(),
    const CashierPage(),
    const TransactionHistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 800,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Inventori'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: Text('Kasir'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('Riwayat'),
              ),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    double totalRevenue = provider.transactions.fold(0, (sum, tx) => sum + tx.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bengkel Pro - Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Hari Ini',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatCard(
                  context,
                  'Total Pendapatan',
                  currencyFormat.format(totalRevenue),
                  Icons.payments,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  'Total Transaksi',
                  provider.transactions.length.toString(),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  'Stok Menipis',
                  provider.spareParts.where((p) => p.stock < 5).length.toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Transaksi Terakhir',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.transactions.take(5).length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final tx = provider.transactions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tx.paymentMethod == PaymentMethod.cash ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      child: Icon(
                        tx.paymentMethod == PaymentMethod.cash ? Icons.money : Icons.qr_code,
                        color: tx.paymentMethod == PaymentMethod.cash ? Colors.green : Colors.blue,
                      ),
                    ),
                    title: Text(tx.customer?.name ?? 'Umum'),
                    subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(tx.date)),
                    trailing: Text(
                      currencyFormat.format(tx.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            if (provider.transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Belum ada transaksi hari ini'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
