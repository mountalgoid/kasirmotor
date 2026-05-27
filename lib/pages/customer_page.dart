import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/workshop_provider.dart';
import '../models/customer.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final filteredCustomers = provider.customers.where((c) =>
      c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pelanggan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showCustomerDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah Pelanggan'),
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
                hintText: 'Cari pelanggan atau plat nomor...',
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
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Nama')),
                          DataColumn(label: Text('Plat Nomor')),
                          DataColumn(label: Text('Tipe Motor')),
                          DataColumn(label: Text('Alamat')),
                          DataColumn(label: Text('Aksi')),
                        ],
                        rows: filteredCustomers.map((customer) => DataRow(
                          cells: [
                            DataCell(Text(customer.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                            DataCell(Text(customer.plateNumber, style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                            DataCell(Text(customer.bikeType, style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                            DataCell(Text(customer.address, style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _showCustomerDialog(context, customer: customer),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _showDeleteConfirmation(context, customer),
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
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDialog(BuildContext context, {Customer? customer}) {
    final nameController = TextEditingController(text: customer?.name);
    final plateController = TextEditingController(text: customer?.plateNumber);
    final typeController = TextEditingController(text: customer?.bikeType);
    final addressController = TextEditingController(text: customer?.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama')),
            TextField(controller: plateController, decoration: const InputDecoration(labelText: 'Plat Nomor')),
            TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Tipe Motor')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Alamat')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newCustomer = Customer(
                  id: customer?.id ?? const Uuid().v4(),
                  name: nameController.text,
                  plateNumber: plateController.text,
                  bikeType: typeController.text,
                  address: addressController.text,
                );

                if (customer == null) {
                  context.read<WorkshopProvider>().addCustomer(newCustomer);
                } else {
                  context.read<WorkshopProvider>().updateCustomer(newCustomer);
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

  void _showDeleteConfirmation(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text('Hapus "${customer.name}" dari daftar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context.read<WorkshopProvider>().deleteCustomer(customer.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
