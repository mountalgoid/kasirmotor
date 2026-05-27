import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:bengkel_pro/providers/workshop_provider.dart';
import 'package:bengkel_pro/providers/settings_provider.dart';
import 'package:bengkel_pro/models/transaction.dart';
import 'package:bengkel_pro/models/customer.dart';
import 'package:bengkel_pro/models/sparepart.dart';
import 'package:bengkel_pro/models/service_item.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
      appBar: AppBar(
        title: Text(isMobile ? 'Kasir' : 'Kasir Ibrahim Part'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => _showAddCustomerDialog(context),
            tooltip: 'Tambah Pelanggan',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => provider.clearCart(),
            tooltip: 'Kosongkan Keranjang',
          ),
          const SizedBox(width: 8),
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
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(service.category, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(format.format(service.price), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        side: BorderSide(color: isOutOfStock ? Colors.grey.withOpacity(0.2) : Colors.red.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: isOutOfStock ? null : () => _showPriceTypeSelector(context, part, format),
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
                  Flexible(child: Text(format.format(part.hargaEcer), style: TextStyle(color: isOutOfStock ? Colors.grey : Colors.red, fontWeight: FontWeight.bold, fontSize: 13))),
                  Text('Stok: ${part.stock}', style: TextStyle(color: isOutOfStock ? Colors.red : (part.stock < 5 ? Colors.orange : Colors.grey), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriceTypeSelector(BuildContext context, SparePart part, NumberFormat format) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(part.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(part.code, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            const Text('Pilih Tipe Harga:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _priceOption(context, 'Harga Ecer', part.hargaEcer, 'Ecer', part, format),
            _priceOption(context, 'Harga Bengkel', part.hargaBengkel, 'Bengkel', part, format),
            _priceOption(context, 'Harga Sales', part.hargaSales, 'Sales', part, format),
            _priceOption(context, 'Harga Beli', part.hargaBeli, 'Beli', part, format),
          ],
        ),
      ),
    );
  }

  Widget _priceOption(BuildContext context, String label, double price, String type, SparePart part, NumberFormat format) {
    return ListTile(
      title: Text(label),
      trailing: Text(format.format(price), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
      onTap: () {
        context.read<WorkshopProvider>().addToCart(part, priceType: type, customPrice: price);
        Navigator.pop(context);
      },
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
                backgroundColor: Colors.red,
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
    return ListView.builder(
      itemCount: provider.cartItems.length,
      itemBuilder: (context, index) {
        final item = provider.cartItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    format.format(item.total),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (item.isService)
                    Text('Jasa • ${item.priceType ?? "Umum"}', style: TextStyle(color: Colors.grey[500], fontSize: 10))
                  else
                    Text('${item.itemCode ?? "Part"} • ${item.priceType ?? "Ecer"}', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    format.format(item.price),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18, color: Colors.red),
                          onPressed: () => context.read<WorkshopProvider>().decreaseCartItemQuantity(index),
                          splashRadius: 18,
                        ),
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18, color: Colors.red),
                          onPressed: () => context.read<WorkshopProvider>().incrementCartItemQuantity(index),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            Text(format.format(provider.cartTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
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
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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
      builder: (context) => Consumer<WorkshopProvider>(
        builder: (context, provider, child) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('Keranjang Belanja', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildCustomerSelector(provider),
              const SizedBox(height: 16),
              Expanded(child: _buildCartItemsList(provider, format)),
              const Divider(),
              _buildTotalSection(provider, format),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: provider.cartItems.isEmpty ? null : () {
                    Navigator.pop(context);
                    _showCheckoutDialog(context, provider);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Lanjutkan Pembayaran'),
                ),
              ),
            ],
          ),
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
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          if (settings.qrisLocalPath != null && !kIsWeb)
                            Image.file(File(settings.qrisLocalPath!), height: 200, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2, size: 80, color: Colors.red))
                          else if (settings.qrisImageUrl.isNotEmpty)
                            Image.network(settings.qrisImageUrl, height: 200, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2, size: 80, color: Colors.red))
                          else
                            const Icon(Icons.qr_code_2, size: 80, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(settings.bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(settings.bankAccountNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.print, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Cetak struk untuk transaksi:'),
            Text(tx.id.substring(0, 8), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nanti')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAndPrintReceipt(tx, context.read<SettingsProvider>());
            },
            child: const Text('Cetak Sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndPrintReceipt(Transaction tx, SettingsProvider settings) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(settings.workshopName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.Text(settings.workshopAddress, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(settings.workshopPhone, style: const pw.TextStyle(fontSize: 10)),
                    pw.Divider(),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('ID: ${tx.id.substring(0, 8)}'),
              pw.Text('Tgl: ${DateFormat('dd/MM/yy HH:mm').format(tx.date)}'),
              pw.Text('Plgn: ${tx.customer?.name ?? "Umum"}'),
              if (tx.customer != null) pw.Text('Plat: ${tx.customer!.plateNumber}'),
              pw.Divider(),
              pw.SizedBox(height: 10),
              ...tx.items.map((item) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(child: pw.Text('${item.name} x${item.quantity}')),
                          pw.Text(currencyFormat.format(item.total)),
                        ],
                      ),
                      if (item.isService)
                        pw.Text('Kategori: ${item.priceType ?? "Umum"}', style: const pw.TextStyle(fontSize: 8))
                      else ...[
                        if (item.itemCode != null)
                          pw.Text('Kode: ${item.itemCode!}', style: const pw.TextStyle(fontSize: 8)),
                        if (item.priceType != null)
                          pw.Text('Tipe: ${item.priceType}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                      pw.SizedBox(height: 4),
                    ],
                  )),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(currencyFormat.format(tx.totalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DIBAYAR (${tx.paymentMethod == PaymentMethod.cash ? "TUNAI" : "TRANSFER"})'),
                  pw.Text(currencyFormat.format(tx.paidAmount)),
                ],
              ),
              if (tx.paymentMethod == PaymentMethod.cash)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('KEMBALI'),
                    pw.Text(currencyFormat.format(tx.change)),
                  ],
                ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Terima Kasih Atas Kunjungan Anda', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
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
