import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/workshop_provider.dart';
import '../providers/settings_provider.dart';
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
    final isMobile = MediaQuery.of(context).size.width < 850;

    final filteredParts = provider.spareParts.where((p) =>
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      p.code.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    final filteredServices = provider.services.where((s) =>
      s.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: isMobile ? null : AppBar(
        title: const Text('Kasir Bengkel'),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt_1), onPressed: () => _showAddCustomerDialog(context)),
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: () => provider.clearCart()),
          const SizedBox(width: 16),
        ],
      ),
      body: isMobile
        ? _buildMobileLayout(provider, currencyFormat, filteredParts, filteredServices)
        : _buildDesktopLayout(provider, currencyFormat, filteredParts, filteredServices),
      floatingActionButton: isMobile && provider.cartItems.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: () => _showCartBottomSheet(context, provider, currencyFormat),
            label: Text('Bayar (${currencyFormat.format(provider.cartTotal)})'),
            icon: const Icon(Icons.shopping_cart),
          )
        : null,
    );
  }

  Widget _buildDesktopLayout(WorkshopProvider provider, NumberFormat format, List<SparePart> parts, List<ServiceItem> services) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchHeader(),
                const SizedBox(height: 24),
                Expanded(child: _buildItemsList(services, parts, format)),
              ],
            ),
          ),
        ),
        _buildCartSidebar(provider, format),
      ],
    );
  }

  Widget _buildMobileLayout(WorkshopProvider provider, NumberFormat format, List<SparePart> parts, List<ServiceItem> services) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildItemsList(services, parts, format)),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<ServiceItem> services, List<SparePart> parts, NumberFormat format) {
    return ListView(
      children: [
        if (services.isNotEmpty) ...[
          const Text('Jasa Servis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: services.map((s) => _buildServiceCard(s, format)).toList(),
          ),
          const SizedBox(height: 24),
        ],
        const Text('Sparepart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: parts.length,
          itemBuilder: (context, index) => _buildPartCard(parts[index], format),
        ),
      ],
    );
  }

  Widget _buildServiceCard(ServiceItem service, NumberFormat format) {
    return InkWell(
      onTap: () => context.read<WorkshopProvider>().addToCart(service),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(format.format(service.price), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPartCard(SparePart part, NumberFormat format) {
    final isOutOfStock = part.stock <= 0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isOutOfStock ? Colors.grey.withOpacity(0.2) : Colors.blue.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: isOutOfStock ? null : () => context.read<WorkshopProvider>().addToCart(part),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(part.name, style: TextStyle(fontWeight: FontWeight.bold, color: isOutOfStock ? Colors.grey : Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(part.code, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(format.format(part.price), style: TextStyle(color: isOutOfStock ? Colors.grey : Colors.blue, fontWeight: FontWeight.bold, fontSize: 13))),
                  Text('Stok: ${part.stock}', style: TextStyle(color: isOutOfStock ? Colors.red : (part.stock < 5 ? Colors.orange : Colors.grey), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSidebar(WorkshopProvider provider, NumberFormat format) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transaksi Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCustomerSelector(provider),
          const SizedBox(height: 24),
          Expanded(child: _buildCartItemsList(provider, format)),
          const Divider(),
          const SizedBox(height: 16),
          _buildTotalSection(provider, format),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: provider.cartItems.isEmpty ? null : () => _showCheckoutDialog(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList(WorkshopProvider provider, NumberFormat format) {
    if (provider.cartItems.isEmpty) {
      return Center(child: Text('Keranjang kosong', style: TextStyle(color: Colors.grey[400])));
    }
    return ListView.separated(
      itemCount: provider.cartItems.length,
      separatorBuilder: (context, index) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final item = provider.cartItems[index];
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${item.quantity}x ${format.format(item.price)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Text(format.format(item.total), style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18), onPressed: () => provider.removeFromCart(index)),
          ],
        );
      },
    );
  }

  Widget _buildTotalSection(WorkshopProvider provider, NumberFormat format) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal'),
            Text(format.format(provider.cartTotal)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(format.format(provider.cartTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Cari jasa atau sparepart...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildCustomerSelector(WorkshopProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              const Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              if (provider.selectedCustomer != null)
                InkWell(onTap: () => provider.selectCustomer(null), child: const Icon(Icons.close, size: 16)),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.selectedCustomer == null)
            DropdownButtonHideUnderline(
              child: DropdownButton<Customer>(
                isExpanded: true,
                hint: const Text('Pilih Pelanggan'),
                items: provider.customers.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.plateNumber})'))).toList(),
                onChanged: (val) => provider.selectCustomer(val),
              ),
            )
          else
            Text('${provider.selectedCustomer!.name} • ${provider.selectedCustomer!.plateNumber}', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context, WorkshopProvider provider, NumberFormat format) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Keranjang Belanja', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(child: _buildCartItemsList(provider, format)),
            const Divider(),
            _buildTotalSection(provider, format),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showCheckoutDialog(context, provider);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Lanjutkan Pembayaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context, WorkshopProvider provider) {
    final settings = context.read<SettingsProvider>();
    _paidAmountController.text = provider.cartTotal.toStringAsFixed(0);
    _paymentMethod = PaymentMethod.cash;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Checkout'),
          content: SingleChildScrollView(
            child: SizedBox(
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
                    onSelectionChanged: (val) => setModalState(() => _paymentMethod = val.first),
                  ),
                  const SizedBox(height: 24),
                  if (_paymentMethod == PaymentMethod.cash) ...[
                    TextField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Jumlah Bayar', prefixText: 'Rp '),
                      onChanged: (val) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _buildChangeCalculation(provider.cartTotal),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          const Icon(Icons.qr_code_2, size: 80, color: Colors.blue),
                          const SizedBox(height: 12),
                          Text(settings.bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(settings.bankAccountNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                          Text('a.n. ${settings.bankAccountName}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final paid = double.tryParse(_paidAmountController.text) ?? 0;
                provider.completeTransaction(paid, _paymentMethod);
                Navigator.pop(context);
                _showPrintDialog(context, provider.transactions.first);
              },
              child: const Text('Selesaikan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrintDialog(BuildContext context, Transaction tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cetak Struk'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.print, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('Simulasi koneksi Bluetooth...'),
            Text('Printer: Thermal-P80 (Terhubung)', style: TextStyle(fontSize: 12, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nanti')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cetak Sekarang')),
        ],
      ),
    );
  }

  Widget _buildChangeCalculation(double total) {
    final paid = double.tryParse(_paidAmountController.text) ?? 0;
    final change = paid - total;
    return Text('Kembalian: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(change < 0 ? 0 : change)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green));
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final plateController = TextEditingController();
    final typeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Pelanggan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama')),
            TextField(controller: plateController, decoration: const InputDecoration(labelText: 'Plat Nomor')),
            TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Tipe Motor')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () {
            context.read<WorkshopProvider>().addCustomer(Customer(id: const Uuid().v4(), name: nameController.text, plateNumber: plateController.text, bikeType: typeController.text));
            Navigator.pop(context);
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
