import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/neo_button.dart';
import 'important_text_provider.dart';
import '../clipboard/clipboard_provider.dart';

class ImportantTextScreen extends ConsumerStatefulWidget {
  const ImportantTextScreen({super.key});

  @override
  ConsumerState<ImportantTextScreen> createState() => _ImportantTextScreenState();
}

class _ImportantTextScreenState extends ConsumerState<ImportantTextScreen> {
  bool _isUnlocked = false;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pin = ref.read(importantTextPinProvider);
      if (pin == null) {
        setState(() => _isUnlocked = true);
      }
      ref.read(importantTextServiceProvider).fetchAndSubscribe();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _textController.dispose();
    // Do not call ref.read(importantTextServiceProvider).dispose(); here 
    // because it might stop subscriptions prematurely if the user navigates back and forth quickly
    super.dispose();
  }

  void _verifyPin() {
    final pin = ref.read(importantTextPinProvider);
    if (_pinController.text == pin) {
      setState(() => _isUnlocked = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN Salah!')),
      );
    }
  }

  void _setPin() async {
    if (_pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN minimal 4 digit!')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('important_text_pin', _pinController.text);
    ref.read(importantTextPinProvider.notifier).state = _pinController.text;
    _pinController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN berhasil disetel!')),
    );
  }

  void _removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('important_text_pin');
    ref.read(importantTextPinProvider.notifier).state = null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN berhasil dihapus!')),
    );
  }

  void _addText() async {
    if (_textController.text.isEmpty) return;
    await ref.read(importantTextServiceProvider).addText(_textController.text);
    _textController.clear();
    Navigator.pop(context);
  }

  void _copyText(String text) {
    ref.read(clipboardActionsProvider).copyToSystemClipboard(text, 'Device Anda');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teks disalin ke clipboard!')),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paperWhite,
        title: const Text('Tambah Teks Penting', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.neoBlack)),
        content: TextField(
          controller: _textController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Masukkan teks di sini...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: AppColors.neoBlack))),
          NeoButton(
            onPressed: _addText,
            backgroundColor: AppColors.acidYellow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.neoBlack)),
          ),
        ],
      ),
    );
  }

  void _showPinSettingsDialog() {
    final hasPin = ref.read(importantTextPinProvider) != null;
    _pinController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paperWhite,
        title: const Text('Pengaturan PIN', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.neoBlack)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Masukkan PIN baru (min 4 digit)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (hasPin)
            TextButton(onPressed: () {
              Navigator.pop(context);
              _removePin();
            }, child: const Text('Hapus PIN', style: TextStyle(color: AppColors.error))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: AppColors.neoBlack))),
          NeoButton(
            onPressed: () {
              Navigator.pop(context);
              _setPin();
            },
            backgroundColor: AppColors.acidYellow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text('Simpan PIN', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.neoBlack)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = ref.watch(importantTextPinProvider) != null;

    if (hasPin && !_isUnlocked) {
      return Scaffold(
        backgroundColor: AppColors.paperWhite,
        appBar: AppBar(title: const Text('Verifikasi PIN')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 64, color: AppColors.neoBlack),
                const SizedBox(height: 24),
                const Text('Halaman ini dilindungi PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.neoBlack)),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                NeoButton(
                  onPressed: _verifyPin,
                  backgroundColor: AppColors.acidYellow,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: const Text('Buka', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.neoBlack)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final history = ref.watch(importantTextHistoryProvider);
    final isLoading = ref.watch(importantTextLoadingProvider);
    final error = ref.watch(importantTextErrorProvider);

    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      appBar: AppBar(
        title: const Text('Teks Penting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.password_rounded),
            onPressed: _showPinSettingsDialog,
            tooltip: 'Pengaturan PIN',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.acidYellow,
        icon: const Icon(Icons.add_rounded, color: AppColors.neoBlack),
        label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.neoBlack)),
      ),
      body: isLoading && history.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.neoBlack))
          : error != null
              ? Center(child: Text(error, style: const TextStyle(color: AppColors.error)))
              : history.isEmpty
                  ? const Center(child: Text('Belum ada teks penting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.paperWhite,
                            border: Border.all(color: AppColors.neoBlack, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(3, 3))],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: AppColors.acidYellow),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item.fromDevice} • ${DateFormat('HH:mm - dd MMM').format(item.timestamp)}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black54),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                                      onPressed: () => ref.read(importantTextServiceProvider).deleteText(item.text, item.fromDevice),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  item.text,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neoBlack),
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: NeoButton(
                                    onPressed: () => _copyText(item.text),
                                    backgroundColor: AppColors.neoBlack,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: const Text('Salin', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.paperWhite)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
