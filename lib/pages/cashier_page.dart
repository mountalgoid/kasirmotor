import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workshop_provider.dart';
import '../models/transaction.dart';
import '../models/customer.dart';
import '../models/sparepart.dart';
import '../models/service_item.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    final filteredParts = provider.spareParts.where((p) =>
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      p.code.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    final filteredServices = provider.services.where((s) =>
      s.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir Bengkel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => _showAddCustomerDialog(context),
            tooltip: 'Tambah Pelanggan',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => provider.clearCart(),
            tooltip: 'Kosongkan Keranjang',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Items Selection Area
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchHeader(context),
                  const SizedBox(height: 24),
                  if (filteredServices.isNotEmpty) ...[
                    const Text('Jasa Servis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          return Card(
                            margin: const EdgeInsets.only(right: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: InkWell(
                              onTap: () => provider.addToCart(service),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                width: 160,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(currencyFormat.format(service.price), style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text('Sparepart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredParts.isEmpty
                      ? const Center(child: Text('Barang tidak ditemukan'))
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filteredParts.length,
                          itemBuilder: (context, index) {
                            final part = filteredParts[index];
                            final isOutOfStock = part.stock <= 0;
                            return Card(
                              elevation: 0,
                              color: isOutOfStock ? Colors.grey[100] : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: isOutOfStock ? Colors.grey.withOpacity(0.2) : Colors.blue.withOpacity(0.1)),
                              ),
                              child: InkWell(
                                onTap: !isOutOfStock ? () => provider.addToCart(part) : null,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(part.name, style: TextStyle(fontWeight: FontWeight.bold, color: isOutOfStock ? Colors.grey : Colors.black87)),
                                      Text(part.code, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(currencyFormat.format(part.price), style: TextStyle(color: isOutOfStock ? Colors.grey : Colors.blue, fontWeight: FontWeight.w600)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isOutOfStock ? Colors.red.withOpacity(0.1) : (part.stock < 5 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Stok: ${part.stock}',
                                              style: TextStyle(
                                                color: isOutOfStock ? Colors.red : (part.stock < 5 ? Colors.orange : Colors.green),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Cart Area
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(-5, 0)),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ringkasan Transaksi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildCustomerSelector(provider),
                  const SizedBox(height: 24),
                  Expanded(
                    child: provider.cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('Keranjang masih kosong', style: TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: provider.cartItems.length,
                            separatorBuilder: (context, index) => const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final item = provider.cartItems[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text('${item.quantity}x ${currencyFormat.format(item.price)}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(currencyFormat.format(item.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      InkWell(
                                        onTap: () => provider.removeFromCart(index),
                                        child: const Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(currencyFormat.format(provider.cartTotal), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: provider.cartItems.isEmpty ? null : () => _showCheckoutDialog(context, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Proses Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelector(WorkshopProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Data Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              if (provider.selectedCustomer != null)
                InkWell(
                  onTap: () => provider.selectCustomer(null),
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                )
            ],
          ),
          const SizedBox(height: 12),
          if (provider.selectedCustomer == null)
            DropdownButtonHideUnderline(
              child: DropdownButton<Customer>(
                isExpanded: true,
                hint: const Text('Pilih Pelanggan (Opsional)'),
                items: provider.customers.map((c) {
                  return DropdownMenuItem(value: c, child: Text('${c.name} - ${c.plateNumber}'));
                }).toList(),
                onChanged: (val) => provider.selectCustomer(val),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.selectedCustomer!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${provider.selectedCustomer!.bikeType} • ${provider.selectedCustomer!.plateNumber}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Cari jasa servis atau sparepart...',
              prefixIcon: const Icon(Icons.search, color: Colors.blue),
              fillColor: Colors.grey[100],
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  })
                : null,
            ),
          ),
        ),
      ],
    );
  }

  void _showCheckoutDialog(BuildContext context, WorkshopProvider provider) {
    _paidAmountController.clear();
    _paidAmountController.text = provider.cartTotal.toStringAsFixed(0);
    _paymentMethod = PaymentMethod.cash;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Konfirmasi Pembayaran'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text('Total Tagihan', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(provider.cartTotal),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _paymentMethodCard(
                      'Tunai',
                      Icons.money,
                      _paymentMethod == PaymentMethod.cash,
                      () => setModalState(() => _paymentMethod = PaymentMethod.cash)
                    ),
                    const SizedBox(width: 12),
                    _paymentMethodCard(
                      'Transfer/QRIS',
                      Icons.qr_code_2,
                      _paymentMethod == PaymentMethod.transfer,
                      () => setModalState(() => _paymentMethod = PaymentMethod.transfer)
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_paymentMethod == PaymentMethod.cash) ...[
                  TextField(
                    controller: _paidAmountController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Uang yang Diterima',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (val) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildChangeCalculation(provider.cartTotal),
                ] else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_scanner, size: 120, color: Colors.blue),
                        const SizedBox(height: 12),
                        const Text('Silahkan Scan QRIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Konfirmasi manual jika dana sudah masuk', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey[600]))
            ),
            ElevatedButton(
              onPressed: () {
                final paid = double.tryParse(_paidAmountController.text) ?? 0;
                if (paid >= provider.cartTotal || _paymentMethod == PaymentMethod.transfer) {
                  provider.completeTransaction(
                    _paymentMethod == PaymentMethod.transfer ? provider.cartTotal : paid,
                    _paymentMethod,
                  );
                  Navigator.pop(context);
                  _showSuccessSnackBar(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Konfirmasi & Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethodCard(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeCalculation(double total) {
    final paid = double.tryParse(_paidAmountController.text) ?? 0;
    final change = paid - total;
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: change >= 0 ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: change >= 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Kembalian', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
          Text(
            currencyFormat.format(change < 0 ? 0 : change),
            style: TextStyle(fontWeight: FontWeight.bold, color: change >= 0 ? Colors.green : Colors.red, fontSize: 20),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Transaksi Berhasil Disimpan'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final plateController = TextEditingController();
    final typeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Pelanggan Baru'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Pelanggan', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: plateController, decoration: const InputDecoration(labelText: 'Nomor Plat', prefixIcon: Icon(Icons.badge))),
            const SizedBox(height: 12),
            TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Tipe Motor', prefixIcon: Icon(Icons.motorcycle))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                context.read<WorkshopProvider>().addCustomer(
                  Customer(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    plateNumber: plateController.text,
                    bikeType: typeController.text,
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pelanggan berhasil ditambahkan')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
