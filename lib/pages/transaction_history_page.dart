import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workshop_provider.dart';
import '../models/transaction.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
      ),
      body: provider.transactions.isEmpty
          ? const Center(child: Text('Belum ada riwayat transaksi'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.transactions.length,
              itemBuilder: (context, index) {
                final tx = provider.transactions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: tx.paymentMethod == PaymentMethod.cash ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      child: Icon(
                        tx.paymentMethod == PaymentMethod.cash ? Icons.money : Icons.qr_code,
                        color: tx.paymentMethod == PaymentMethod.cash ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(tx.customer?.name ?? 'Umum'),
                    subtitle: Text(dateFormat.format(tx.date)),
                    trailing: Text(
                      currencyFormat.format(tx.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (tx.customer != null) ...[
                              Text('Info Kendaraan: ${tx.customer!.bikeType} (${tx.customer!.plateNumber})'),
                              const Divider(),
                            ],
                            const Text('Rincian:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...tx.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${item.name} x${item.quantity}'),
                                            if (item.isService)
                                               Text('Kategori: ${item.priceType ?? "Umum"}', style: TextStyle(color: Colors.grey[500], fontSize: 10))
                                            else ...[
                                              if (item.itemCode != null)
                                                Text('Kode: ${item.itemCode!}', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                                              if (item.priceType != null)
                                                Text('Tipe: ${item.priceType}', style: TextStyle(color: Colors.red[300], fontSize: 10)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Text(currencyFormat.format(item.total)),
                                    ],
                                  ),
                                )),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Tagihan'),
                                Text(currencyFormat.format(tx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Dibayar (${tx.paymentMethod == PaymentMethod.cash ? "Tunai" : "Transfer"})'),
                                Text(currencyFormat.format(tx.paidAmount)),
                              ],
                            ),
                            if (tx.paymentMethod == PaymentMethod.cash)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Kembalian'),
                                  Text(currencyFormat.format(tx.change), style: const TextStyle(color: Colors.green)),
                                ],
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
