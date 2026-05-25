import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSection(
            context,
            'Informasi Bengkel',
            [
              _buildSettingItem(
                context,
                'Nama Bengkel',
                settings.workshopName,
                Icons.store,
                () => _showEditDialog(context, 'Nama Bengkel', settings.workshopName, (val) => settings.updateSettings(name: val)),
              ),
              _buildSettingItem(
                context,
                'Alamat',
                settings.workshopAddress,
                Icons.location_on,
                () => _showEditDialog(context, 'Alamat', settings.workshopAddress, (val) => settings.updateSettings(address: val)),
              ),
              _buildSettingItem(
                context,
                'Nomor Telepon',
                settings.workshopPhone,
                Icons.phone,
                () => _showEditDialog(context, 'Nomor Telepon', settings.workshopPhone, (val) => settings.updateSettings(phone: val)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Pembayaran & QRIS',
            [
              _buildSettingItem(
                context,
                'Nama Bank',
                settings.bankName,
                Icons.account_balance,
                () => _showEditDialog(context, 'Nama Bank', settings.bankName, (val) => settings.updateSettings(bank: val)),
              ),
              _buildSettingItem(
                context,
                'Nomor Rekening',
                settings.bankAccountNumber,
                Icons.numbers,
                () => _showEditDialog(context, 'Nomor Rekening', settings.bankAccountNumber, (val) => settings.updateSettings(accountNum: val)),
              ),
              _buildSettingItem(
                context,
                'Nama Pemilik Rekening',
                settings.bankAccountName,
                Icons.person,
                () => _showEditDialog(context, 'Nama Pemilik', settings.bankAccountName, (val) => settings.updateSettings(accountName: val)),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Gambar QRIS'),
                subtitle: const Text('Atur gambar QRIS untuk pembayaran'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Placeholder for image picker
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur pilih gambar akan segera hadir')));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(BuildContext context, String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit_outlined, size: 20),
      onTap: onTap,
    );
  }

  void _showEditDialog(BuildContext context, String title, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah $title'),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: 'Masukkan $title baru')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () { onSave(controller.text); Navigator.pop(context); }, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
