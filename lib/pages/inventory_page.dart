import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workshop_provider.dart';
import '../models/sparepart.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Stok Sparepart'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddPartDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Barang'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Search & Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari nama barang atau kode...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: 'Semua',
                  items: ['Semua', 'Stok Rendah', 'Habis'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (_) {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Kode')),
                    DataColumn(label: Text('Nama Barang')),
                    DataColumn(label: Text('Harga')),
                    DataColumn(label: Text('Stok')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Aksi')),
                  ],
                  rows: provider.spareParts.map((part) {
                    final isLow = part.stock < 5;
                    return DataRow(cells: [
                      DataCell(Text(part.code)),
                      DataCell(Text(part.name)),
                      DataCell(Text(currencyFormat.format(part.price))),
                      DataCell(Text(part.stock.toString())),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLow ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isLow ? 'Stok Rendah' : 'Tersedia',
                            style: TextStyle(
                              color: isLow ? Colors.orange : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () {}),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () {}),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPartDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Sparepart Baru'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Kode Barang')),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Barang')),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Harga Jual'), keyboardType: TextInputType.number),
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stok Awal'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                context.read<WorkshopProvider>().addSparePart(
                  SparePart(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                    stock: int.tryParse(stockController.text) ?? 0,
                    code: codeController.text,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
