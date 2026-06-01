import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/clipboard_model.dart';
import '../../core/services/clipboard_service.dart';
import '../../shared/widgets/neo_button.dart';
import '../settings/settings_provider.dart';
import 'clipboard_provider.dart';
import '../../core/constants/app_colors.dart';
import 'clipboard_auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../important_text/important_text_screen.dart';

class ClipboardScreen extends ConsumerStatefulWidget {
  const ClipboardScreen({super.key});

  @override
  ConsumerState<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends ConsumerState<ClipboardScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submitPin() async {
    if (_pinController.text.isEmpty) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    
    // We need a short delay just for visual feedback if it's too fast
    await Future.delayed(const Duration(milliseconds: 300));
    final success = await unlockWithPin(ref, _pinController.text);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!success) {
          _errorMsg = 'PIN Salah!';
          _pinController.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncEnabled = ref.watch(clipboardSyncEnabledProvider);
    final history = ref.watch(filteredClipboardHistoryProvider);
    final allHistory = ref.watch(clipboardHistoryProvider);
    final connectedDevices = ref.watch(clipboardConnectionsProvider);
    final isUnlocked = ref.watch(clipboardAuthStatusProvider);
    final isConnected = connectedDevices.isNotEmpty;
    final errorMessage = ref.watch(clipboardErrorProvider);

    // Build list of unique devices from all history
    final devices = ['Semua', ...allHistory.map((e) => e.fromDevice).toSet()];
    final activeFilter = ref.watch(clipboardFilterDeviceProvider) ?? 'Semua';
    final activeSort = ref.watch(clipboardSortProvider);

    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      appBar: AppBar(
        title: const Text(AppStrings.clipboardTitle),
      ),
      body: !isUnlocked ? _buildLockedScreen() : CustomScrollView(
        slivers: [
          // Toggle sync card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: syncEnabled ? AppColors.acidYellow : AppColors.paperWhite,
                  border: Border.all(color: AppColors.neoBlack, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: AppColors.neoBlack, offset: Offset(4, 4)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.neoBlack,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              syncEnabled ? Icons.cloud_sync_rounded : Icons.cloud_off_rounded,
                              color: AppColors.acidYellow,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Supabase Sync',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.neoBlack,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Sinkronisasi via Cloud (Realtime)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: syncEnabled,
                            onChanged: (value) {
                              ref.read(settingsProvider.notifier).updateClipboardAutoSync(value);
                            },
                          ),
                        ],
                      ),
                      if (syncEnabled) ...[
                        const Divider(height: 24, thickness: 2, color: AppColors.neoBlack),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Status Koneksi:',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neoBlack,
                                ),
                              ),
                            ),
                            NeoButton(
                              onPressed: () => ref.read(clipboardServiceProvider).reconnect(),
                              backgroundColor: isConnected ? AppColors.neoGreen : AppColors.error,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shadowOffset: const Offset(2, 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                                    color: AppColors.paperWhite,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isConnected ? 'Terhubung' : 'Terputus',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.paperWhite,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              border: Border.all(color: AppColors.error, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: const TextStyle(
                                      color: AppColors.neoBlack,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Teks Penting Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: NeoButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportantTextScreen()));
                },
                backgroundColor: AppColors.paperWhite,
                padding: const EdgeInsets.all(16),
                shadowOffset: const Offset(4, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.acidYellow, size: 28),
                    const SizedBox(width: 12),
                    const Text('Teks Penting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.neoBlack)),
                  ],
                ),
              ),
            ),
          ),

          if (allHistory.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'KLIPBOARD SAAT INI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppColors.neoBlack,
                  ),
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildCurrentClipboardCard(context, ref, allHistory.first),
              ),
            ),
          ],

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
              child: Text(
                'RIWAYAT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.neoBlack,
                ),
              ),
            ),
          ),

          // Filter & Sort Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.paperWhite,
                        border: Border.all(color: AppColors.neoBlack, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(2, 2))],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: activeFilter,
                          isExpanded: true,
                          icon: const Icon(Icons.filter_list_rounded, color: AppColors.neoBlack),
                          items: devices.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            ref.read(clipboardFilterDeviceProvider.notifier).state = newValue;
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.paperWhite,
                        border: Border.all(color: AppColors.neoBlack, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(2, 2))],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ClipboardSort>(
                          value: activeSort,
                          isExpanded: true,
                          icon: const Icon(Icons.sort_rounded, color: AppColors.neoBlack),
                          items: const [
                            DropdownMenuItem(value: ClipboardSort.newest, child: Text('Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                            DropdownMenuItem(value: ClipboardSort.oldest, child: Text('Lama', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                          ],
                          onChanged: (newValue) {
                            if (newValue != null) {
                              ref.read(clipboardSortProvider.notifier).state = newValue;
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (history.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.paperWhite,
                        border: Border.all(color: AppColors.neoBlack, width: 2),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(4, 4))],
                      ),
                      child: const Icon(
                        Icons.content_paste_off_rounded,
                        size: 48,
                        color: AppColors.neoBlack,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tidak ada riwayat',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.neoBlack,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = history[index];
                    return _buildHistoryCard(context, ref, item);
                  },
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLockedScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.acidYellow,
                border: Border.all(color: AppColors.neoBlack, width: 3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(6, 6))],
              ),
              child: const Icon(Icons.lock_person_rounded, size: 64, color: AppColors.neoBlack),
            ),
            const SizedBox(height: 32),
            const Text(
              'Akses Terkunci',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.neoBlack),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan PIN rahasia untuk membuka fitur Sinkronisasi Clipboard, atau tunggu perangkat lain membagikan kunci.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Masukkan PIN',
                errorText: _errorMsg,
                filled: true,
                fillColor: AppColors.paperWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.neoBlack, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.neoBlack, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.neoBlack, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: NeoButton(
                onPressed: _isLoading ? () {} : _submitPin,
                backgroundColor: AppColors.neoBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.acidYellow, strokeWidth: 3))
                  : const Text('Buka Kunci', style: TextStyle(color: AppColors.acidYellow, fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentClipboardCard(BuildContext context, WidgetRef ref, ClipboardModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.neoBlack, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(4, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.acidYellow,
                    border: Border.all(color: AppColors.neoBlack, width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.fromDevice,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.neoBlack,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('HH:mm').format(item.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neoBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SelectableText(
              item.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.neoBlack,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NeoButton(
                  onPressed: () => ref.read(clipboardServiceProvider).toggleLock(item),
                  backgroundColor: item.isLocked ? AppColors.neoBlack : AppColors.paperWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shadowOffset: const Offset(2, 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 16, color: item.isLocked ? AppColors.acidYellow : AppColors.neoBlack),
                      const SizedBox(width: 8),
                      Text(item.isLocked ? 'Terkunci' : 'Kunci', style: TextStyle(fontWeight: FontWeight.w900, color: item.isLocked ? AppColors.acidYellow : AppColors.neoBlack)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                NeoButton(
                  onPressed: () => _copyText(context, ref, item.text),
                  backgroundColor: AppColors.neoBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shadowOffset: const Offset(2, 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded, size: 16, color: AppColors.acidYellow),
                      const SizedBox(width: 8),
                      const Text('Salin Ulang', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.acidYellow)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, WidgetRef ref, ClipboardModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.neoBlack, width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(2, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neoBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.devices_rounded, size: 12, color: Colors.grey.shade800),
                      const SizedBox(width: 4),
                      Text(
                        '${item.fromDevice} • ${DateFormat('HH:mm').format(item.timestamp)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            NeoButton(
              onPressed: () => ref.read(clipboardServiceProvider).toggleLock(item),
              backgroundColor: item.isLocked ? AppColors.neoBlack : AppColors.paperWhite,
              padding: const EdgeInsets.all(8),
              shadowOffset: const Offset(2, 2),
              child: Icon(item.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 18, color: item.isLocked ? AppColors.acidYellow : AppColors.neoBlack),
            ),
            const SizedBox(width: 8),
            NeoButton(
              onPressed: () => _copyText(context, ref, item.text),
              backgroundColor: AppColors.acidYellow,
              padding: const EdgeInsets.all(8),
              shadowOffset: const Offset(2, 2),
              child: const Icon(Icons.copy_rounded, size: 18, color: AppColors.neoBlack),
            ),
          ],
        ),
      ),
    );
  }

  void _copyText(BuildContext context, WidgetRef ref, String text) {
    ref.read(clipboardActionsProvider).copyToSystemClipboard(text, 'Device Anda');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(AppStrings.clipboardCopied),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
