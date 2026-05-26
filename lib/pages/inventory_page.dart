import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workshop_provider.dart';
import '../models/sparepart.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _searchQuery = '';
  String _filterStatus = 'Semua';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    // Apply filters
    final filteredParts = provider.spareParts.where((part) {
      final matchesSearch = part.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           part.code.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesStatus = true;
      if (_filterStatus == 'Stok Rendah') {
        matchesStatus = part.stock < 5 && part.stock > 0;
      } else if (_filterStatus == 'Habis') {
        matchesStatus = part.stock <= 0;
      }

      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Stok Sparepart'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showPartDialog(context),
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
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    underline: const SizedBox(),
                    items: ['Semua', 'Stok Rendah', 'Habis'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _filterStatus = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Kode')),
                      DataColumn(label: Text('Nama Barang')),
                      DataColumn(label: Text('Hrg Beli')),
                      DataColumn(label: Text('Hrg Sales')),
                      DataColumn(label: Text('Hrg Bengkel')),
                      DataColumn(label: Text('Hrg Ecer')),
                      DataColumn(label: Text('Stok')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows: filteredParts.map((part) {
                      final isOutOfStock = part.stock <= 0;
                      final isLow = part.stock < 5 && !isOutOfStock;

                      return DataRow(cells: [
                        DataCell(Text(part.code)),
                        DataCell(Text(part.name)),
                        DataCell(Text(currencyFormat.format(part.purchasePrice))),
                        DataCell(Text(currencyFormat.format(part.sellingPriceSales))),
                        DataCell(Text(currencyFormat.format(part.sellingPriceWorkshop))),
                        DataCell(Text(currencyFormat.format(part.sellingPriceRetail))),
                        DataCell(Text(part.stock.toString())),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                ? Colors.red.withOpacity(0.1)
                                : (isLow ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOutOfStock ? 'Habis' : (isLow ? 'Stok Rendah' : 'Tersedia'),
                              style: TextStyle(
                                color: isOutOfStock ? Colors.red : (isLow ? Colors.orange : Colors.green),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showPartDialog(context, part: part),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _showDeleteConfirmation(context, part),
                                tooltip: 'Hapus',
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPartDialog(BuildContext context, {SparePart? part}) {
    final nameController = TextEditingController(text: part?.name);
    final purchasePriceController = TextEditingController(text: part?.purchasePrice.toStringAsFixed(0));
    final salesPriceController = TextEditingController(text: part?.sellingPriceSales.toStringAsFixed(0));
    final workshopPriceController = TextEditingController(text: part?.sellingPriceWorkshop.toStringAsFixed(0));
    final retailPriceController = TextEditingController(text: part?.sellingPriceRetail.toStringAsFixed(0));
    final stockController = TextEditingController(text: part?.stock.toString());
    final codeController = TextEditingController(text: part?.code);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(part == null ? 'Tambah Sparepart Baru' : 'Edit Sparepart'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Kode Barang')),
                const SizedBox(height: 8),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Barang')),
                const SizedBox(height: 8),
                TextField(controller: purchasePriceController, decoration: const InputDecoration(labelText: 'Harga Beli'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(controller: salesPriceController, decoration: const InputDecoration(labelText: 'Harga Sales'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(controller: workshopPriceController, decoration: const InputDecoration(labelText: 'Harga Bengkel'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(controller: retailPriceController, decoration: const InputDecoration(labelText: 'Harga Ecer'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stok'), keyboardType: TextInputType.number),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newPart = SparePart(
                  id: part?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  purchasePrice: double.tryParse(purchasePriceController.text) ?? 0,
                  sellingPriceSales: double.tryParse(salesPriceController.text) ?? 0,
                  sellingPriceWorkshop: double.tryParse(workshopPriceController.text) ?? 0,
                  sellingPriceRetail: double.tryParse(retailPriceController.text) ?? 0,
                  stock: int.tryParse(stockController.text) ?? 0,
                  code: codeController.text,
                );

                if (part == null) {
                  context.read<WorkshopProvider>().addSparePart(newPart);
                } else {
                  context.read<WorkshopProvider>().updateSparePart(newPart);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(part == null ? 'Barang berhasil ditambah' : 'Barang berhasil diupdate')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, SparePart part) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus "${part.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context.read<WorkshopProvider>().deleteSparePart(part.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Barang berhasil dihapus'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
