// lib/core/constants/app_strings.dart

class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'LShare';
  static const String appTagline = 'Berbagi file tanpa internet';

  // Navigation
  static const String navHome = 'Beranda';
  static const String navHistory = 'Riwayat';
  static const String navClipboard = 'Clipboard';
  static const String navSettings = 'Pengaturan';

  static const String noDeviceFound = 'Tidak ada device ditemukan';

  // Home Screen
  static const String homeTitle = 'Beranda';
  static const String homeDeviceOnline = 'Device Online';
  static const String homeNoDevice = 'Tidak ada device lain ditemukan';
  static const String homeNoDeviceSubtitle =
      'Pastikan device lain terhubung ke WiFi yang sama dan membuka LShare';
  static const String homeSearching = 'Mencari device...';
  static const String homeYourDevice = 'Device Anda';
  static const String homeSendFile = 'Kirim File';
  static const String homeWifiStatus = 'WiFi Aktif';
  static const String homeWifiOff = 'WiFi Tidak Aktif';
  static const String homeWifiOffMessage =
      'Hubungkan ke WiFi untuk menggunakan LShare';

  // Send Screen
  static const String sendTitle = 'Kirim File';
  static const String sendSelectFile = 'Pilih File';
  static const String sendSelectFileHint = 'Ketuk untuk memilih file';
  static const String sendSelectTarget = 'Pilih Tujuan';
  static const String sendButton = 'Kirim';
  static const String sendSending = 'Mengirim...';
  static const String sendSuccess = 'Selesai';
  static const String sendFailed = 'Gagal';
  static const String sendCancelled = 'Dibatalkan';
  static const String sendNoDeviceSelected = 'Pilih device tujuan terlebih dahulu';
  static const String sendNoFileSelected = 'Pilih file terlebih dahulu';
  static const String sendRejected = 'Transfer ditolak oleh penerima';

  // Receive Screen
  static const String receiveTitle = 'Kiriman Masuk';
  static const String receiveFrom = 'Dari';
  static const String receiveFile = 'File';
  static const String receiveSize = 'Ukuran';
  static const String receiveAccept = 'Terima';
  static const String receiveReject = 'Tolak';
  static const String receiveAutoReject = 'Otomatis ditolak dalam';
  static const String receiveDownloading = 'Mengunduh...';
  static const String receiveSuccess = 'File berhasil diterima';
  static const String receiveFailed = 'Gagal menerima file';

  // Clipboard Screen
  static const String clipboardTitle = 'Clipboard';
  static const String clipboardSync = 'Sinkronisasi Clipboard';
  static const String clipboardSyncSubtitle = 'Bagikan clipboard ke semua device';
  static const String clipboardCurrent = 'Clipboard Saat Ini';
  static const String clipboardHistory = 'Riwayat';
  static const String clipboardEmpty = 'Belum ada riwayat clipboard';
  static const String clipboardCopy = 'Salin';
  static const String clipboardCopied = 'Disalin ke clipboard';
  static const String clipboardFrom = 'Dari';

  // History Screen
  static const String historyTitle = 'Riwayat';
  static const String historyAll = 'Semua';
  static const String historySent = 'Terkirim';
  static const String historyReceived = 'Diterima';
  static const String historyEmpty = 'Belum ada riwayat transfer';
  static const String historyEmptySubtitle =
      'Riwayat transfer file akan muncul di sini';
  static const String historyDeleteConfirm = 'Hapus item ini dari riwayat?';
  static const String historyDelete = 'Hapus';
  static const String historyCancel = 'Batal';

  // Settings Screen
  static const String settingsTitle = 'Pengaturan';
  static const String settingsDeviceName = 'Nama Device';
  static const String settingsDeviceNameHint = 'Masukkan nama device Anda';
  static const String settingsSaveFolder = 'Folder Penyimpanan';
  static const String settingsClipboardAutoSync = 'Sinkronisasi Clipboard Otomatis';
  static const String settingsConfirmReceive = 'Konfirmasi Sebelum Menerima';
  static const String settingsConfirmReceiveSubtitle =
      'Tampilkan dialog konfirmasi saat ada file masuk';
  static const String settingsAppVersion = 'Versi Aplikasi';
  static const String settingsSave = 'Simpan';
  static const String settingsSaved = 'Pengaturan tersimpan';

  // Status labels
  static const String statusPending = 'Menunggu';
  static const String statusTransferring = 'Mengirim';
  static const String statusDone = 'Selesai';
  static const String statusFailed = 'Gagal';
  static const String statusRejected = 'Ditolak';

  // General
  static const String ok = 'OK';
  static const String cancel = 'Batal';
  static const String yes = 'Ya';
  static const String no = 'Tidak';
  static const String retry = 'Coba Lagi';
  static const String close = 'Tutup';
  static const String open = 'Buka';
  static const String error = 'Terjadi kesalahan';
  static const String unknownDevice = 'Device Tidak Dikenal';
  static const String unknownFile = 'File tidak diketahui';
}
