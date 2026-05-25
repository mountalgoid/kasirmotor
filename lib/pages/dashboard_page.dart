import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/workshop_provider.dart';
import '../models/transaction.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final isMobile = MediaQuery.of(context).size.width < 850;

    double totalRevenue = provider.transactions.fold(0, (sum, tx) => sum + tx.totalAmount);
    int totalPartsSold = provider.transactions.fold(0, (sum, tx) => sum + tx.items.where((i) => !i.isService).length);

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Selamat datang kembali di Bengkel Pro', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                if (!isMobile)
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download),
                    label: const Text('Unduh Laporan'),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            // Stat Cards
            isMobile
              ? Column(
                  children: [
                    _buildStatCard(context, 'Pendapatan', currencyFormat.format(totalRevenue), Icons.payments, Colors.green),
                    const SizedBox(height: 12),
                    _buildStatCard(context, 'Transaksi', provider.transactions.length.toString(), Icons.shopping_cart, Colors.blue),
                    const SizedBox(height: 12),
                    _buildStatCard(context, 'Stok Menipis', provider.spareParts.where((p) => p.stock < 5).length.toString(), Icons.warning, Colors.orange),
                  ],
                )
              : Row(
                  children: [
                    _buildStatCard(context, 'Pendapatan Total', currencyFormat.format(totalRevenue), Icons.payments, Colors.green),
                    const SizedBox(width: 16),
                    _buildStatCard(context, 'Total Transaksi', provider.transactions.length.toString(), Icons.shopping_cart, Colors.blue),
                    const SizedBox(width: 16),
                    _buildStatCard(context, 'Sparepart Terjual', totalPartsSold.toString(), Icons.build, Colors.purple),
                    const SizedBox(width: 16),
                    _buildStatCard(context, 'Stok Menipis', provider.spareParts.where((p) => p.stock < 5).length.toString(), Icons.warning, Colors.orange),
                  ],
                ),
            const SizedBox(height: 32),
            // Charts & Recent Transactions
            if (isMobile) ...[
              _buildRevenueChart(context, provider),
              const SizedBox(height: 24),
              _buildRecentTransactions(context, provider, currencyFormat),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildRevenueChart(context, provider)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildRecentTransactions(context, provider, currencyFormat)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context, WorkshopProvider provider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Grafik Pendapatan (7 Hari Terakhir)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 1),
                        FlSpot(2, 4),
                        FlSpot(3, 2),
                        FlSpot(4, 5),
                        FlSpot(5, 3),
                        FlSpot(6, 4),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, WorkshopProvider provider, NumberFormat format) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaksi Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (provider.transactions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada data')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.transactions.take(5).length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final tx = provider.transactions[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: const Icon(Icons.receipt_long, color: Colors.blue, size: 20),
                    ),
                    title: Text(tx.customer?.name ?? 'Umum', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(DateFormat('HH:mm').format(tx.date), style: const TextStyle(fontSize: 12)),
                    trailing: Text(format.format(tx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      flex: MediaQuery.of(context).size.width < 850 ? 0 : 1,
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.1))),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
