import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/workshop_provider.dart';
import '../models/service_item.dart';

class ServiceManagementPage extends StatefulWidget {
  const ServiceManagementPage({super.key});

  @override
  State<ServiceManagementPage> createState() => _ServiceManagementPageState();
}

class _ServiceManagementPageState extends State<ServiceManagementPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    final filteredServices = provider.services.where((s) =>
      s.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Jasa Servis'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showServiceDialog(context),
              icon: const Icon(Icons.add_task),
              label: const Text('Tambah Jasa'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari jasa servis...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
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
                      columns: const [
                      DataColumn(label: Text('Nama Jasa')),
                      DataColumn(label: Text('Kategori')),
                      DataColumn(label: Text('Harga')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows: filteredServices.map((service) => DataRow(
                      cells: [
                        DataCell(Text(service.name)),
                        DataCell(Text(service.category)),
                        DataCell(Text(currencyFormat.format(service.price))),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showServiceDialog(context, service: service),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _showDeleteConfirmation(context, service),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )).toList(),
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

  void _showServiceDialog(BuildContext context, {ServiceItem? service}) {
    final nameController = TextEditingController(text: service?.name);
    final priceController = TextEditingController(text: service?.price.toStringAsFixed(0));
    final categoryController = TextEditingController(text: service?.category ?? 'Umum');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service == null ? 'Tambah Jasa Servis' : 'Edit Jasa Servis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Jasa')),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Kategori (contoh: Mesin, Kelistrikan)')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Harga'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                final newService = ServiceItem(
                  id: service?.id ?? const Uuid().v4(),
                  name: nameController.text,
                  category: categoryController.text,
                  price: double.tryParse(priceController.text) ?? 0,
                );

                if (service == null) {
                  context.read<WorkshopProvider>().addServiceItem(newService);
                } else {
                  context.read<WorkshopProvider>().updateServiceItem(newService);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ServiceItem service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jasa'),
        content: Text('Hapus jasa "${service.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context.read<WorkshopProvider>().deleteServiceItem(service.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
