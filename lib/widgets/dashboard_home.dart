import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/workshop_provider.dart';
import '../models/transaction.dart';

class ChartData {
  final String label;
  final double amount;
  ChartData(this.label, this.amount);
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  String _chartFilter = '1 Minggu';

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
                    Text('Selamat datang kembali di Ibrahim Part', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                if (!isMobile)
                  ElevatedButton.icon(
                    onPressed: () => _downloadReport(provider),
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
    final filteredData = _getFilteredChartData(provider.transactions);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Grafik Pendapatan ($_chartFilter)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                DropdownButton<String>(
                  value: _chartFilter,
                  items: ['1 Hari', '1 Minggu', '1 Bulan', '1 Tahun'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _chartFilter = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: filteredData.isEmpty
                  ? const Center(child: Text('Data belum tersedia'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (filteredData.isEmpty) return const Text('');
                                int index = value.toInt();
                                if (index < 0 || index >= filteredData.length) return const Text('');
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(filteredData[index].label, style: const TextStyle(fontSize: 10)),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(filteredData.length, (i) => FlSpot(i.toDouble(), filteredData[i].amount)),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 4,
                            dotData: const FlDotData(show: true),
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

  List<ChartData> _getFilteredChartData(List<Transaction> transactions) {
    final now = DateTime.now();
    List<ChartData> data = [];

    if (_chartFilter == '1 Hari') {
      // Group by hours (last 24 hours)
      for (int i = 23; i >= 0; i--) {
        final time = now.subtract(Duration(hours: i));
        final amount = transactions
            .where((tx) => tx.date.year == time.year && tx.date.month == time.month && tx.date.day == time.day && tx.date.hour == time.hour)
            .fold(0.0, (sum, tx) => sum + tx.totalAmount);
        data.add(ChartData(DateFormat('HH:00').format(time), amount));
      }
    } else if (_chartFilter == '1 Minggu') {
      // Group by days (last 7 days)
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final amount = transactions
            .where((tx) => tx.date.year == date.year && tx.date.month == date.month && tx.date.day == date.day)
            .fold(0.0, (sum, tx) => sum + tx.totalAmount);
        data.add(ChartData(DateFormat('dd/MM').format(date), amount));
      }
    } else if (_chartFilter == '1 Bulan') {
      // Group by days (last 30 days)
      for (int i = 29; i >= 0; i -= 3) {
        final date = now.subtract(Duration(days: i));
        final amount = transactions
            .where((tx) => tx.date.isAfter(date.subtract(const Duration(days: 3))) && tx.date.isBefore(date.add(const Duration(seconds: 1))))
            .fold(0.0, (sum, tx) => sum + tx.totalAmount);
        data.add(ChartData(DateFormat('dd/MM').format(date), amount));
      }
    } else if (_chartFilter == '1 Tahun') {
      // Group by months (last 12 months)
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final amount = transactions
            .where((tx) => tx.date.year == date.year && tx.date.month == date.month)
            .fold(0.0, (sum, tx) => sum + tx.totalAmount);
        data.add(ChartData(DateFormat('MMM').format(date), amount));
      }
    }

    return data;
  }

  Future<void> _downloadReport(WorkshopProvider provider) async {
    String csv = 'ID Transaksi,Tanggal,Pelanggan,Total Tagihan,Metode Pembayaran,Item Terjual\n';
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    for (var tx in provider.transactions) {
      // Escape commas in names
      final customerName = (tx.customer?.name ?? 'Umum').replaceAll(',', ' ');

      String itemsStr = tx.items.map((i) {
        String detail = i.name;
        if (i.itemCode != null) detail += ' [${i.itemCode}]';
        if (i.priceType != null) detail += ' (${i.priceType})';
        return detail;
      }).join(' | ');
      itemsStr = '"$itemsStr"'; // Quote to handle commas/pipes in details

      csv += '${tx.id},${dateFormat.format(tx.date)},$customerName,${tx.totalAmount},${tx.paymentMethod == PaymentMethod.cash ? "Tunai" : "Transfer"},$itemsStr\n';
    }

    if (kIsWeb) {
      // For web, printing to console as a fallback since dart:html is needed for real download
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Laporan berhasil dibuat (CSV) - Lihat Console'),
          action: SnackBarAction(label: 'Print', onPressed: () => print(csv)),
        ),
      );
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/laporan_bengkel_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
        final file = File(path);
        await file.writeAsString(csv);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan disimpan di: $path'),
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan laporan: $e')),
        );
      }
    }
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
