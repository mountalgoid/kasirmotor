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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    final todayTransactions = provider.transactions.where((tx) =>
      tx.date.isAfter(today.subtract(const Duration(seconds: 1)))).toList();

    final yesterdayTransactions = provider.transactions.where((tx) =>
      tx.date.isAfter(yesterday.subtract(const Duration(seconds: 1))) &&
      tx.date.isBefore(today)).toList();

    final weekTransactions = provider.transactions.where((tx) =>
      tx.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))).toList();

    final monthTransactions = provider.transactions.where((tx) =>
      tx.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1)))).toList();

    final yearTransactions = provider.transactions.where((tx) =>
      tx.date.isAfter(startOfYear.subtract(const Duration(seconds: 1)))).toList();

    double todayRevenue = todayTransactions.fold(0, (sum, tx) => sum + tx.totalAmount);
    double todayProfit = todayTransactions.fold(0, (sum, tx) => sum + tx.totalProfit);
    int todayCount = todayTransactions.length;

    double todayCashRevenue = todayTransactions
        .where((tx) => tx.paymentMethod == PaymentMethod.cash)
        .fold(0, (sum, tx) => sum + tx.totalAmount);
    double todayTransferRevenue = todayTransactions
        .where((tx) => tx.paymentMethod == PaymentMethod.transfer)
        .fold(0, (sum, tx) => sum + tx.totalAmount);
    double todayAvgTransactionValue = todayCount > 0 ? todayRevenue / todayCount : 0;

    double weekRevenue = weekTransactions.fold(0, (sum, tx) => sum + tx.totalAmount);
    double monthRevenue = monthTransactions.fold(0, (sum, tx) => sum + tx.totalAmount);
    double yearRevenue = yearTransactions.fold(0, (sum, tx) => sum + tx.totalAmount);

    double yesterdayRevenue = yesterdayTransactions.fold(0, (sum, tx) => sum + tx.totalAmount);

    double revenueTrend = yesterdayRevenue == 0
        ? (todayRevenue > 0 ? 100 : 0)
        : ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;

    int totalPartsSold = provider.transactions.fold(0, (sum, tx) => sum + tx.items.where((i) => !i.isService).length);

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Analisis Bisnis Realtime', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _downloadReport(provider),
                  icon: const Icon(Icons.download),
                  label: const Text('Unduh Laporan'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Stat Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 600 ? 2 : (constraints.maxWidth < 900 ? 2 : 4);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: constraints.maxWidth < 600 ? 1.3 : 1.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      context,
                      'Pendapatan Hari Ini',
                      currencyFormat.format(todayRevenue),
                      Icons.today,
                      Colors.green,
                      subtitle: 'Cash: ${currencyFormat.format(todayCashRevenue)} | Trf: ${currencyFormat.format(todayTransferRevenue)}',
                      trend: revenueTrend,
                      onTap: () => _showRevenueDetails(context, provider, currencyFormat),
                    ),
                    _buildStatCard(
                      context,
                      'Minggu Ini',
                      currencyFormat.format(weekRevenue),
                      Icons.calendar_view_week,
                      Colors.teal,
                      subtitle: 'Total Minggu Ini',
                      onTap: () => _showRevenueDetails(context, provider, currencyFormat),
                    ),
                    _buildStatCard(
                      context,
                      'Bulan Ini',
                      currencyFormat.format(monthRevenue),
                      Icons.calendar_month,
                      Colors.indigo,
                      subtitle: 'Total Bulan Ini',
                      onTap: () => _showRevenueDetails(context, provider, currencyFormat),
                    ),
                    _buildStatCard(
                      context,
                      'Tahun Ini',
                      currencyFormat.format(yearRevenue),
                      Icons.analytics,
                      Colors.amber[900]!,
                      subtitle: 'Total Tahun Ini',
                      onTap: () => _showRevenueDetails(context, provider, currencyFormat),
                    ),
                    _buildStatCard(
                      context,
                      'Transaksi Hari Ini',
                      '$todayCount Transaksi',
                      Icons.shopping_cart,
                      Colors.blue,
                      subtitle: 'Rata-rata: ${currencyFormat.format(todayAvgTransactionValue)}',
                      onTap: () => _showTransactionDetails(context, provider, currencyFormat),
                    ),
                    _buildStatCard(context, 'Terjual', totalPartsSold.toString(), Icons.assignment_turned_in, Colors.purple, onTap: () => _showItemsSoldDetails(context, provider, currencyFormat)),
                  ],
                );
              }
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
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
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                                String text = '';
                                if (value >= 1000000) {
                                  text = '${(value / 1000000).toStringAsFixed(1)}M';
                                } else if (value >= 1000) {
                                  text = '${(value / 1000).toStringAsFixed(0)}K';
                                } else {
                                  text = value.toStringAsFixed(0);
                                }
                                return Text(text, style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (filteredData.isEmpty) return const Text('');
                                int index = value.toInt();
                                if (index < 0 || index >= filteredData.length) return const Text('');
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(filteredData[index].label, style: const TextStyle(fontSize: 9)),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              final format = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  format.format(spot.y),
                                  TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(filteredData.length, (i) => FlSpot(i.toDouble(), filteredData[i].amount)),
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 4,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
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
      // Group by hours (last 24 hours, starting from 23 hours ago)
      for (int i = 23; i >= 0; i--) {
        final time = now.subtract(Duration(hours: i));
        final hourStart = DateTime(time.year, time.month, time.day, time.hour);
        final hourEnd = hourStart.add(const Duration(hours: 1));

        final amount = transactions
            .where((tx) => tx.date.isAfter(hourStart.subtract(const Duration(seconds: 1))) &&
                           tx.date.isBefore(hourEnd))
            .fold(0.0, (sum, tx) => sum + tx.totalAmount);

        // Only label every 4 hours to avoid overlap
        String label = (i % 4 == 0 || i == 0 || i == 23) ? DateFormat('HH:00').format(time) : '';
        data.add(ChartData(label, amount));
      }
    } else if (_chartFilter == '1 Minggu') {
      // Group by days (last 7 days)
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final amount = transactions
            .where((tx) => tx.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
                           tx.date.isBefore(dayEnd))
            .fold(0.0, (sum, tx) => sum + tx.totalAmount);
        data.add(ChartData(DateFormat('dd/MM').format(date), amount));
      }
    } else if (_chartFilter == '1 Bulan') {
      // Group by days (last 30 days, showing every 2-3 days for clarity)
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final amount = transactions
            .where((tx) => tx.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
                           tx.date.isBefore(dayEnd))
            .fold(0.0, (sum, tx) => sum + tx.totalAmount);

        // Add all days but only label some for readability
        String label = (i % 5 == 0 || i == 0) ? DateFormat('dd/MM').format(date) : '';
        data.add(ChartData(label, amount));
      }
    } else if (_chartFilter == '1 Tahun') {
      // Group by months (last 12 months)
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthStart = DateTime(date.year, date.month, 1);
        final nextMonth = date.month == 12 ? DateTime(date.year + 1, 1, 1) : DateTime(date.year, date.month + 1, 1);

        final amount = transactions
            .where((tx) => tx.date.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
                           tx.date.isBefore(nextMonth))
            .fold(0.0, (sum, tx) => sum + tx.totalAmount);

        // Only label every 2 months to avoid overlap
        String label = (i % 2 == 0 || i == 0 || i == 11) ? DateFormat('MMM').format(date) : '';
        data.add(ChartData(label, amount));
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
                      backgroundColor: Colors.red.withOpacity(0.1),
                      child: const Icon(Icons.receipt_long, color: Colors.red, size: 20),
                    ),
                    title: Text(tx.customer?.name ?? 'Umum', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateFormat('HH:mm').format(tx.date)} • ${tx.items.length} item',
                          style: const TextStyle(fontSize: 11)
                        ),
                        Text(
                          tx.items.map((i) => i.name).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    trailing: Text(format.format(tx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRevenueDetails(BuildContext context, WorkshopProvider provider, NumberFormat format) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    double getRev(List<Transaction> txs) => txs.fold(0, (sum, t) => sum + t.totalAmount);
    double getProfit(List<Transaction> txs) => txs.fold(0, (sum, t) => sum + t.totalProfit);

    final todayT = provider.transactions.where((tx) => tx.date.isAfter(today.subtract(const Duration(seconds: 1)))).toList();
    final weekT = provider.transactions.where((tx) => tx.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))).toList();
    final monthT = provider.transactions.where((tx) => tx.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1)))).toList();
    final yearT = provider.transactions.where((tx) => tx.date.isAfter(startOfYear.subtract(const Duration(seconds: 1)))).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan Pendapatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _revenueSection('Hari Ini', getRev(todayT), getProfit(todayT), format, Colors.green),
            const Divider(),
            _revenueSection('Minggu Ini', getRev(weekT), getProfit(weekT), format, Colors.teal),
            const Divider(),
            _revenueSection('Bulan Ini', getRev(monthT), getProfit(monthT), format, Colors.indigo),
            const Divider(),
            _revenueSection('Tahun Ini', getRev(yearT), getProfit(yearT), format, Colors.orange),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _revenueSection(String label, double revenue, double profit, NumberFormat format, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          _detailRow('Omzet', format.format(revenue)),
          _detailRow('Laba Bersih', format.format(profit), color: Colors.green),
        ],
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, WorkshopProvider provider, NumberFormat format) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transaksi Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: provider.transactions.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final tx = provider.transactions[index];
                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      shape: const RoundedRectangleBorder(side: BorderSide.none),
                      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                      title: Text(tx.customer?.name ?? 'Umum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${DateFormat('dd/MM/yy HH:mm').format(tx.date)} • ${tx.items.length} item', style: const TextStyle(fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(format.format(tx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
                          Text('Profit: ${format.format(tx.totalProfit)}', style: const TextStyle(fontSize: 10, color: Colors.green)),
                        ],
                      ),
                      children: tx.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.isService ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.isService ? 'Jasa' : 'Part',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: item.isService ? Colors.blue : Colors.orange,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  if (item.itemCode != null)
                                    Text(item.itemCode!, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                                ],
                              ),
                            ),
                            Text('${item.quantity}x ', style: const TextStyle(fontSize: 12)),
                            SizedBox(
                              width: 80,
                              child: Text(
                                format.format(item.total),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemsSoldDetails(BuildContext context, WorkshopProvider provider, NumberFormat format) {
    Map<String, int> parts = {};
    Map<String, int> services = {};

    for (var tx in provider.transactions) {
      for (var item in tx.items) {
        if (item.isService) {
          services[item.name] = (services[item.name] ?? 0) + item.quantity;
        } else {
          parts[item.name] = (parts[item.name] ?? 0) + item.quantity;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detail Item Terjual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (services.isNotEmpty) ...[
                      const Text('Jasa Servis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const Divider(),
                      ...services.entries.map((e) => ListTile(title: Text(e.key), trailing: Text('${e.value}x'))),
                      const SizedBox(height: 24),
                    ],
                    if (parts.isNotEmpty) ...[
                      const Text('Sparepart', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const Divider(),
                      ...parts.entries.map((e) => ListTile(title: Text(e.key), trailing: Text('${e.value}x'))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLowStockDetails(BuildContext context, WorkshopProvider provider, NumberFormat format) {
    final lowStockItems = provider.spareParts.where((p) => p.stock < 5).toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Peringatan Stok Rendah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 16),
            if (lowStockItems.isEmpty)
              const Center(child: Text('Semua stok aman'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: lowStockItems.length,
                  itemBuilder: (context, index) {
                    final item = lowStockItems[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('${item.stock}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(item.name),
                      subtitle: Text('Kode: ${item.code}'),
                      trailing: Text(format.format(item.hargaBeli), style: const TextStyle(fontSize: 12)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    double? trend,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.1))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trend != null)
                    Icon(
                      trend >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: trend >= 0 ? Colors.green : Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
