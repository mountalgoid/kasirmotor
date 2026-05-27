import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
                subtitle: Text(settings.qrisLocalPath != null || settings.qrisImageUrl.isNotEmpty ? 'Sudah diatur' : 'Belum diatur'),
                trailing: _buildQrisPreview(settings),
                onTap: () => _showQrisOptions(context, settings),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildQrisPreview(SettingsProvider settings) {
    if (settings.qrisLocalPath != null && !kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(File(settings.qrisLocalPath!), width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
      );
    } else if (settings.qrisImageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(settings.qrisImageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
      );
    }
    return const Icon(Icons.chevron_right);
  }

  void _showQrisOptions(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pilih dari Galeri'),
            onTap: () async {
              Navigator.pop(context);
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                settings.updateSettings(qrisPath: image.path, qris: kIsWeb ? image.path : '');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Masukkan URL Gambar'),
            onTap: () {
              Navigator.pop(context);
              _showEditDialog(
                context,
                'URL Gambar QRIS',
                settings.qrisImageUrl,
                (val) => settings.updateSettings(qris: val, qrisPath: null),
                hint: 'Masukkan URL gambar QRIS'
              );
            },
          ),
        ],
      ),
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

  void _showEditDialog(BuildContext context, String title, String initialValue, Function(String) onSave, {String? hint}) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah $title'),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: hint ?? 'Masukkan $title baru')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () { onSave(controller.text); Navigator.pop(context); }, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
