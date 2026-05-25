import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workshop_provider.dart';
import '../models/transaction.dart';
import '../models/customer.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final TextEditingController _paidAmountController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
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
                  const SizedBox(height: 16),
                  const Text('Jasa Servis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.services.length,
                      itemBuilder: (context, index) {
                        final service = provider.services[index];
                        return Card(
                          margin: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: () => provider.addToCart(service),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              width: 150,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(currencyFormat.format(service.price), style: const TextStyle(fontSize: 12, color: Colors.blue)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Sparepart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: provider.spareParts.length,
                      itemBuilder: (context, index) {
                        final part = provider.spareParts[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: InkWell(
                            onTap: part.stock > 0 ? () => provider.addToCart(part) : null,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(part.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(part.code, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(currencyFormat.format(part.price), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                                      Text('Stok: ${part.stock}', style: TextStyle(color: part.stock < 5 ? Colors.red : Colors.grey, fontSize: 11)),
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
              color: Colors.grey[50],
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detail Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Customer Selection
                  _buildCustomerSelector(provider),
                  const SizedBox(height: 16),
                  Expanded(
                    child: provider.cartItems.isEmpty
                        ? const Center(child: Text('Keranjang kosong'))
                        : ListView.separated(
                            itemCount: provider.cartItems.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = provider.cartItems[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.name),
                                subtitle: Text('${item.quantity}x ${currencyFormat.format(item.price)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(currencyFormat.format(item.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                      onPressed: () => provider.removeFromCart(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(currencyFormat.format(provider.cartTotal), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: provider.cartItems.isEmpty ? null : () => _showCheckoutDialog(context, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Bayar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold)),
              if (provider.selectedCustomer != null)
                TextButton(onPressed: () => provider.selectCustomer(null), child: const Text('Hapus'))
            ],
          ),
          if (provider.selectedCustomer == null)
            DropdownButton<Customer>(
              isExpanded: true,
              hint: const Text('Pilih Pelanggan'),
              underline: const SizedBox(),
              items: provider.customers.map((c) {
                return DropdownMenuItem(value: c, child: Text('${c.name} - ${c.plateNumber}'));
              }).toList(),
              onChanged: (val) => provider.selectCustomer(val),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.selectedCustomer!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('${provider.selectedCustomer!.bikeType} (${provider.selectedCustomer!.plateNumber})', style: TextStyle(color: Colors.grey[600])),
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
            decoration: InputDecoration(
              hintText: 'Cari jasa atau sparepart...',
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.grey[100],
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () {},
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Selesaikan Pembayaran'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<PaymentMethod>(
                  segments: const [
                    ButtonSegment(value: PaymentMethod.cash, label: Text('Tunai'), icon: Icon(Icons.money)),
                    ButtonSegment(value: PaymentMethod.transfer, label: Text('Transfer/QRIS'), icon: Icon(Icons.qr_code)),
                  ],
                  selected: {_paymentMethod},
                  onSelectionChanged: (newVal) {
                    setModalState(() => _paymentMethod = newVal.first);
                  },
                ),
                const SizedBox(height: 24),
                Text('Total Tagihan', style: TextStyle(color: Colors.grey[600])),
                Text(
                  NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(provider.cartTotal),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 24),
                if (_paymentMethod == PaymentMethod.cash) ...[
                  TextField(
                    controller: _paidAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Bayar',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildChangeCalculation(provider.cartTotal),
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: const Column(
                      children: [
                        Icon(Icons.qr_code_2, size: 100, color: Colors.blue),
                        SizedBox(height: 8),
                        Text('Tunjukkan QRIS ke pelanggan', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Konfirmasi manual setelah transfer masuk', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
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
              child: const Text('Konfirmasi & Cetak'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeCalculation(double total) {
    final paid = double.tryParse(_paidAmountController.text) ?? 0;
    final change = paid - total;
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: change >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Kembalian', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            currencyFormat.format(change < 0 ? 0 : change),
            style: TextStyle(fontWeight: FontWeight.bold, color: change >= 0 ? Colors.green : Colors.red, fontSize: 18),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaksi Berhasil Disimpan'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Pelanggan')),
            TextField(controller: plateController, decoration: const InputDecoration(labelText: 'Nomor Plat (Contoh: B 1234 ABC)')),
            TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Tipe Motor (Contoh: Vario 125)')),
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
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
