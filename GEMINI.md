# GEMINI.md — LShare
> **Product Requirements Document (PRD) + Implementation Guide**
> Nama Aplikasi: **LShare**
> Pembuat: **Syaifulloh R**
> Platform: **Android (Flutter/Dart)**
> Versi Dokumen: 1.0 — Mei 2026
 
---
 
## 🧠 INSTRUKSI UNTUK AI
 
Kamu adalah expert Flutter developer yang membantu membangun aplikasi **LShare**.
Baca seluruh dokumen ini sebelum mulai bekerja.
 
**Aturan kerja:**
- Kerjakan **satu fase dalam satu waktu**
- Setelah selesai satu fase, **laporkan apa yang sudah dibuat** sebelum lanjut
- Jangan skip fase atau mengerjakan dua fase sekaligus
- Jika ada ambiguitas, **tanya dulu** sebelum implementasi
- Selalu gunakan **null safety** dan **best practice Flutter terbaru**
- Gunakan **Riverpod** untuk state management
- Gunakan **Material 3** untuk UI
---
 
## 📋 RINGKASAN PRODUK
 
| Atribut | Detail |
|---|---|
| Nama | LShare |
| Pembuat | Syaifulloh R |
| Platform Target | Android (min SDK 21 / Android 5.0) |
| Framework | Flutter (Dart) |
| State Management | Riverpod (flutter_riverpod) |
| UI Design System | Material 3 |
| Bahasa UI | Indonesia |
| Jaringan | WiFi LAN lokal (tidak butuh internet) |
 
### Apa itu LShare?
LShare adalah aplikasi Android yang memungkinkan transfer file (foto, video, dokumen) dan sinkronisasi clipboard (teks) antar device yang terhubung ke WiFi yang sama. Tidak ada server cloud, tidak ada internet — semua berjalan lokal di jaringan rumah.
 
### Cara Kerja Singkat
1. Setiap device yang membuka LShare otomatis menjadi **server HTTP lokal** di port `8080`
2. Device saling menemukan lewat **mDNS broadcast** di jaringan lokal
3. Transfer file via **HTTP multipart POST**
4. Clipboard sync via **WebSocket**
---
 
## 🏗️ ARSITEKTUR & KEPUTUSAN TEKNIS
 
> Ini adalah keputusan yang TIDAK boleh berubah antar fase.
 
### Struktur Folder Project
```
lib/
├── main.dart
├── app.dart                    # MaterialApp + ProviderScope
├── core/
│   ├── constants/
│   │   ├── app_colors.dart     # Warna Material 3
│   │   ├── app_strings.dart    # Semua string UI (Indonesia)
│   │   └── app_constants.dart  # PORT, timeout, dll
│   ├── models/
│   │   ├── device_model.dart   # Model device yang ditemukan
│   │   ├── transfer_model.dart # Model progress transfer
│   │   └── clipboard_model.dart
│   ├── services/
│   │   ├── discovery_service.dart   # mDNS discovery
│   │   ├── server_service.dart      # HTTP server lokal (shelf)
│   │   ├── transfer_service.dart    # Kirim/terima file
│   │   └── clipboard_service.dart   # WebSocket clipboard sync
│   └── utils/
│       ├── file_utils.dart
│       ├── network_utils.dart
│       └── permission_utils.dart
├── features/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── home_provider.dart
│   ├── devices/
│   │   ├── device_card.dart
│   │   └── devices_provider.dart
│   ├── send/
│   │   ├── send_screen.dart
│   │   ├── send_provider.dart
│   │   └── progress_widget.dart
│   ├── receive/
│   │   ├── receive_screen.dart
│   │   └── receive_provider.dart
│   ├── clipboard/
│   │   ├── clipboard_screen.dart
│   │   └── clipboard_provider.dart
│   ├── history/
│   │   ├── history_screen.dart
│   │   └── history_provider.dart
│   └── settings/
│       ├── settings_screen.dart
│       └── settings_provider.dart
└── shared/
    ├── widgets/
    │   ├── app_scaffold.dart
    │   ├── device_avatar.dart
    │   └── transfer_progress_bar.dart
    └── theme/
        └── app_theme.dart
```
 
### Konstanta Teknis
```dart
// lib/core/constants/app_constants.dart
const int kServerPort = 8080;
const int kWebSocketPort = 8081;
const String kMdnsServiceType = '_lshare._tcp';
const String kAppName = 'LShare';
const int kChunkSize = 1024 * 1024; // 1MB chunks
const Duration kDiscoveryTimeout = Duration(seconds: 5);
const Duration kConnectionTimeout = Duration(seconds: 10);
```
 
### Dependency (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
 
  # Networking
  shelf: ^1.4.1
  shelf_router: ^1.1.4
  shelf_web_socket: ^1.0.4
  bonsoir: ^5.1.3              # mDNS discovery
  dio: ^5.4.3                  # HTTP client untuk kirim file
  web_socket_channel: ^2.4.5
 
  # File & Storage
  file_picker: ^8.0.3
  path_provider: ^2.1.3
  permission_handler: ^11.3.1
  open_filex: ^4.3.4
 
  # UI & Utils
  google_fonts: ^6.2.1
  flutter_local_notifications: ^17.2.2
  crypto: ^3.0.3
  mime: ^1.0.5
  intl: ^0.19.0
  shared_preferences: ^2.2.3
 
dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  flutter_lints: ^3.0.0
```
 
### Model Data
```dart
// DeviceModel
class DeviceModel {
  final String id;          // UUID unik tiap device
  final String name;        // Nama device (bisa diubah user)
  final String ip;          // IP lokal (misal: 192.168.1.5)
  final int port;           // Default: 8080
  final String platform;    // 'android' | 'windows' | 'macos'
  final bool isOnline;
  final DateTime lastSeen;
}
 
// TransferModel
class TransferModel {
  final String id;
  final String fileName;
  final int fileSize;
  final String fromDevice;
  final String toDevice;
  final TransferStatus status; // pending|transferring|done|failed|rejected
  final double progress;       // 0.0 - 1.0
  final DateTime timestamp;
}
 
// ClipboardModel
class ClipboardModel {
  final String text;
  final String fromDevice;
  final DateTime timestamp;
}
```
 
---
 
## 📱 HALAMAN APLIKASI
 
| Halaman | Route | Deskripsi |
|---|---|---|
| Home | `/` | Daftar device aktif di jaringan |
| Send | `/send` | Pilih file dan kirim ke device |
| Receive | (overlay) | Pop-up saat ada kiriman masuk |
| Clipboard | `/clipboard` | Toggle sync + riwayat clipboard |
| History | `/history` | Riwayat transfer masuk/keluar |
| Settings | `/settings` | Nama device, folder simpan, dll |
 
---
 
## 🗺️ TAHAPAN PENGERJAAN (FASE)
 
---
 
### ✅ FASE 0 — Persiapan & Setup Project
**Tujuan:** Project siap di-run di Android, semua dependency terpasang, struktur folder sudah ada.
 
**Yang harus dikerjakan:**
1. Update `pubspec.yaml` dengan semua dependency di atas
2. Buat seluruh struktur folder `lib/` sesuai arsitektur
3. Buat file-file konstanta (`app_constants.dart`, `app_colors.dart`, `app_strings.dart`)
4. Setup `main.dart` dengan `ProviderScope` dan `MaterialApp`
5. Setup `app_theme.dart` dengan Material 3, warna biru sebagai primary
6. Buat `app.dart` sebagai root widget
7. Buat halaman placeholder untuk semua screen (scaffold kosong dengan judul)
8. Setup `AndroidManifest.xml` dengan semua permission yang diperlukan
9. Jalankan `flutter pub get` dan pastikan build sukses
**Kriteria selesai:**
- [ ] `flutter run` berhasil di Android tanpa error
- [ ] Semua halaman placeholder bisa diakses via navigasi sederhana
- [ ] Tema Material 3 dengan warna biru sudah aktif
- [ ] Tidak ada import error atau missing dependency
**Laporkan setelah selesai:**
```
FASE 0 SELESAI
- pubspec.yaml: [status]
- Struktur folder: [status]
- AndroidManifest.xml: [status]
- Build status: [sukses/error]
```
 
---
 
### ✅ FASE 1 — Core Services: Discovery (mDNS)
**Tujuan:** Device bisa menemukan device lain yang menjalankan LShare di jaringan WiFi yang sama.
 
**Yang harus dikerjakan:**
1. Buat `lib/core/services/discovery_service.dart`:
   - Fungsi `startBroadcast()` — daftarkan device ke mDNS
   - Fungsi `startDiscovery()` — scan device LShare lain di jaringan
   - Fungsi `stopAll()` — stop semua service
   - Stream `devicesStream` yang emit list `DeviceModel` terbaru
2. Buat `lib/core/models/device_model.dart` lengkap dengan `fromJson`, `toJson`, `copyWith`
3. Buat `lib/features/devices/devices_provider.dart` menggunakan Riverpod
4. Update `HomeScreen` untuk menampilkan daftar device:
   - Card tiap device: nama, IP, status online
   - Empty state: "Tidak ada device lain ditemukan."
   - Loading state saat discovery berjalan
5. Buat `device_card.dart` widget
**Kriteria selesai:**
- [ ] Device A muncul di list Device B dan sebaliknya (dalam WiFi yang sama)
- [ ] Saat device keluar app, hilang dari list dalam 10 detik
- [ ] Tidak ada crash saat WiFi tidak aktif
**Laporkan setelah selesai:**
```
FASE 1 SELESAI
- discovery_service.dart: [dibuat]
- device_model.dart: [dibuat]
- devices_provider.dart: [dibuat]
- HomeScreen: [diupdate]
- Test result: [berhasil/gagal]
```
 
---
 
### ✅ FASE 2 — Core Services: HTTP Server Lokal
**Tujuan:** Setiap device menjadi server HTTP yang bisa menerima file dan permintaan.
 
**Yang harus dikerjakan:**
1. Buat `lib/core/services/server_service.dart` menggunakan `shelf`:
   - `POST /receive` — endpoint menerima file (multipart)
   - `GET /ping` — cek apakah device online
   - `POST /request` — terima permintaan transfer
   - `POST /clipboard` — terima teks clipboard
   - `GET /info` — info device (nama, platform)
   - Server berjalan di `0.0.0.0:8080`
2. Buat `lib/core/utils/network_utils.dart`:
   - `getLocalIpAddress()` — dapatkan IP lokal
   - `isWifiConnected()` — cek WiFi aktif
3. Buat `lib/core/utils/permission_utils.dart`
4. Buat `lib/core/utils/file_utils.dart`:
   - `getSaveDirectory()` — path Downloads/LShare
   - `formatFileSize(int bytes)` — "1.2 MB"
5. Server start otomatis saat app buka, stop saat app tutup
**Kriteria selesai:**
- [ ] `GET http://<ip>:8080/ping` mengembalikan `{"status":"ok","name":"<nama>"}`
- [ ] Server auto-start dan auto-stop
- [ ] IP lokal tampil di HomeScreen
**Laporkan setelah selesai:**
```
FASE 2 SELESAI
- server_service.dart: [dibuat]
- Endpoints aktif: [list]
- IP detection: [berhasil/gagal]
```
 
---
 
### ✅ FASE 3 — Fitur Transfer File (Kirim)
**Tujuan:** User bisa memilih file dan mengirimnya ke device lain.
 
**Yang harus dikerjakan:**
1. Buat `lib/core/services/transfer_service.dart`:
   - `sendFile(DeviceModel target, PlatformFile file)` via HTTP POST multipart
   - Progress tracking via `Dio` `onSendProgress`
   - Verifikasi MD5 checksum
2. Buat `lib/core/models/transfer_model.dart`
3. Buat `lib/features/send/send_screen.dart`:
   - Tombol besar "Pilih File"
   - Preview file yang dipilih
   - Daftar device online sebagai tujuan
   - Tombol "Kirim"
4. Buat `lib/features/send/send_provider.dart`
5. Buat `lib/shared/widgets/transfer_progress_bar.dart`
6. Navigasi: tap device di HomeScreen → SendScreen dengan device terpilih
**Kriteria selesai:**
- [ ] Bisa pilih berbagai tipe file
- [ ] Progress bar muncul saat transfer
- [ ] File tersimpan di `Downloads/LShare/` di penerima
- [ ] Transfer 50MB berhasil tanpa crash
**Laporkan setelah selesai:**
```
FASE 3 SELESAI
- transfer_service.dart: [dibuat]
- send_screen.dart: [dibuat]
- Test file besar: [ukuran, durasi, hasil]
```
 
---
 
### ✅ FASE 4 — Fitur Transfer File (Terima)
**Tujuan:** Device penerima mendapat notifikasi dan bisa terima atau tolak kiriman.
 
**Yang harus dikerjakan:**
1. Update endpoint `POST /request` — trigger notifikasi lokal
2. Buat `lib/features/receive/receive_screen.dart` (bottom sheet):
   - Tampilkan: nama pengirim, nama file, ukuran
   - Tombol "Terima" dan "Tolak"
   - Auto-dismiss 30 detik jika tidak direspons
3. Buat `lib/features/receive/receive_provider.dart`
4. Update `POST /receive` — hanya terima jika user sudah konfirmasi
5. Setup `flutter_local_notifications` untuk background
6. Notifikasi saat file berhasil diterima
**Kriteria selesai:**
- [ ] Dialog muncul saat ada kiriman
- [ ] "Terima" → file didownload dengan progress
- [ ] "Tolak" → pengirim dapat notifikasi ditolak
- [ ] Notifikasi saat app di background
**Laporkan setelah selesai:**
```
FASE 4 SELESAI
- Receive dialog: [dibuat]
- Notifikasi background: [berhasil/gagal]
- Test end-to-end: [hasil]
```
 
---
 
### ✅ FASE 5 — Fitur Clipboard Sync
**Tujuan:** Teks yang di-copy di satu device otomatis tersedia di device lain.
 
**Yang harus dikerjakan:**
1. Buat `lib/core/services/clipboard_service.dart`:
   - WebSocket server di port `8081`
   - Monitor perubahan clipboard setiap 500ms
   - Broadcast ke semua device saat clipboard berubah
   - Terima clipboard dari device lain
2. Buat `lib/core/models/clipboard_model.dart`
3. Buat `lib/features/clipboard/clipboard_screen.dart`:
   - Toggle ON/OFF sync
   - Tampilkan teks clipboard terkini
   - Riwayat 10 item terakhir dengan "Dari: [device] • [jam]"
   - Tombol "Salin" di tiap item
4. Buat `lib/features/clipboard/clipboard_provider.dart`
**Kriteria selesai:**
- [ ] Copy di Device A → tersedia di Device B dalam 1 detik
- [ ] Toggle OFF menghentikan sync
- [ ] Riwayat 10 clipboard terakhir tampil
- [ ] Tidak crash jika koneksi terputus
**Laporkan setelah selesai:**
```
FASE 5 SELESAI
- clipboard_service.dart: [dibuat]
- clipboard_screen.dart: [dibuat]
- Test latency: [xx ms]
```
 
---
 
### ✅ FASE 6 — Riwayat Transfer & Persistensi
**Tujuan:** User bisa melihat semua file yang pernah dikirim dan diterima.
 
**Yang harus dikerjakan:**
1. Buat `lib/features/history/history_screen.dart`:
   - List semua transfer (terkirim + diterima)
   - Filter: Semua | Terkirim | Diterima
   - Tiap item: ikon tipe file, nama, ukuran, device, waktu, status
   - Tap item → buka file dengan `open_filex`
   - Swipe to delete
2. Buat `lib/features/history/history_provider.dart`
3. Simpan ke `shared_preferences` (max 100 item)
**Kriteria selesai:**
- [ ] Semua transfer tercatat
- [ ] Filter berfungsi
- [ ] Tap file → terbuka dengan app yang sesuai
- [ ] Persisten setelah app restart
**Laporkan setelah selesai:**
```
FASE 6 SELESAI
- history_screen.dart: [dibuat]
- Persistensi: [berhasil/gagal]
- Test buka file: [hasil per tipe]
```
 
---
 
### ✅ FASE 7 — Settings & Polish UI
**Tujuan:** App terasa polished dan siap dipakai sehari-hari.
 
**Yang harus dikerjakan:**
1. Buat `lib/features/settings/settings_screen.dart`:
   - Nama device (tersimpan di shared_preferences)
   - Folder penyimpanan
   - Toggle clipboard auto-sync
   - Toggle konfirmasi sebelum terima
   - Info versi app
2. Implementasi Bottom Navigation Bar (4 tab: Beranda, Riwayat, Clipboard, Pengaturan)
3. Polish UI:
   - Animasi transisi halaman
   - Empty states yang informatif
   - Error states (WiFi mati, tidak ada device, transfer gagal)
   - Loading states konsisten
   - Snackbar untuk feedback
4. HomeScreen final: header nama device + IP, chip status WiFi, FAB "Kirim File"
**Kriteria selesai:**
- [ ] Bottom nav berfungsi
- [ ] Nama device bisa diubah dan tersimpan
- [ ] Semua empty state tampil
- [ ] Tidak ada overflow UI
**Laporkan setelah selesai:**
```
FASE 7 SELESAI
- settings_screen.dart: [dibuat]
- Bottom nav: [berfungsi]
- Polish: [list item yang dipolish]
```
 
---
 
### ✅ FASE 8 — Testing & Bug Fixing
**Tujuan:** Aplikasi stabil dan siap dipakai keluarga.
 
**Yang harus dikerjakan:**
1. Test skenario utama:
   - [ ] Transfer foto 5MB antar HP
   - [ ] Transfer video 100MB antar HP
   - [ ] Transfer PDF antar HP
   - [ ] Clipboard sync teks panjang
   - [ ] App background terima file
   - [ ] Putus WiFi saat transfer
   - [ ] Device keluar saat transfer
2. Bug fixing berdasar hasil test
3. Optimasi: dispose semua service, minimize battery drain
4. Update README.md
**Kriteria selesai:**
- [ ] Semua skenario test lulus
- [ ] Tidak ada crash yang diketahui
- [ ] README.md terupdate
**Laporkan setelah selesai:**
```
FASE 8 SELESAI
- Test: [lulus/total]
- Bug diperbaiki: [list]
- APK size: [xx MB]
```
 
---
 
## 📐 UI/UX GUIDELINES
 
### Warna (Material 3)
```dart
primary: Color(0xFF1E88E5)        // Biru utama
onPrimary: Colors.white
primaryContainer: Color(0xFFE3F2FD)
secondary: Color(0xFF0D47A1)      // Biru tua
background: Color(0xFFF8F9FA)
surface: Colors.white
```
 
### Bahasa UI (Selalu Indonesia)
```
"Tidak ada device ditemukan"
"Pilih File" / "Kirim" / "Terima" / "Tolak"
"Mengirim..." / "Selesai" / "Gagal"
"Pengaturan" / "Riwayat" / "Beranda"
```
 
---
 
## 🔒 PERMISSION ANDROID
 
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```
 
---
 
## 📊 PROGRESS TRACKER
 
| Fase | Nama | Status | Tanggal Selesai |
|------|------|--------|-----------------|
| 0 | Setup & Persiapan | ✅ Selesai | 22 Mei 2026 |
| 1 | mDNS Discovery | ✅ Selesai | 22 Mei 2026 |
| 2 | HTTP Server Lokal | ✅ Selesai | 23 Mei 2026 |
| 3 | Transfer File (Kirim) | ✅ Selesai | 23 Mei 2026 |
| 4 | Transfer File (Terima) | ✅ Selesai | 23 Mei 2026 |
| 5 | Clipboard Sync | ✅ Selesai | 23 Mei 2026 |
| 6 | Riwayat & Persistensi | ✅ Selesai | 23 Mei 2026 |
| 7 | Settings & Polish | ✅ Selesai | 23 Mei 2026 |
| 8 | Testing & Bug Fix | ✅ Selesai | 23 Mei 2026 |
 
> Status: ⬜ Belum → 🔄 Sedang → ✅ Selesai
 