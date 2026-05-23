# 🚀 LShare — Local Share & Clipboard Sync

LShare adalah aplikasi Android (Flutter) modern yang memungkinkan Anda melakukan transfer file (foto, video, dokumen) dan sinkronisasi clipboard (teks) secara nirkabel antar perangkat yang terhubung ke jaringan WiFi/LAN lokal yang sama. 

Aplikasi ini berjalan **100% offline secara lokal** tanpa membutuhkan server cloud ataupun koneksi internet, menjadikannya sangat cepat, aman, dan menjaga privasi data Anda.

---

## ✨ Fitur Utama

- **Offline & Private**: Semua lalu lintas data berjalan di dalam jaringan lokal rumah Anda. Tidak ada data yang dikirim ke cloud.
- **Auto-Discovery (mDNS)**: Perangkat saling mendeteksi secara otomatis tanpa perlu memasukkan IP address manual menggunakan multicast DNS (mDNS) broadcast.
- **Transfer File Kecepatan Tinggi**: Kirim file ukuran kecil hingga besar (video 100MB+) dengan lancar menggunakan HTTP multipart POST stream.
- **Penerimaan Konvergen (Dialog Konfirmasi)**: Menampilkan dialog overlay bottom sheet saat ada transfer masuk dengan hitungan mundur 30 detik. Penerima dapat memilih untuk Menerima atau Menolak.
- **Sinkronisasi Clipboard Instan (WebSocket)**: Salin teks di satu perangkat, dan teks tersebut akan langsung tersedia di clipboard perangkat lain secara real-time via WebSocket.
- **Riwayat Transfer & Persistensi**: Riwayat pengiriman/penerimaan tersimpan secara aman (maksimal 100 log teratas) dan file yang diterima dapat langsung dibuka menggunakan aplikasi eksternal (`open_filex`).
- **Desain Premium Material 3**: Antarmuka modern yang estetik dengan warna biru primary, lengkap dengan status reaktif server lokal, WiFi status chip, dan transisi navigasi halaman yang mulus.

---

## 🛠️ Keputusan Teknis & Port Jaringan

LShare beroperasi sebagai server lokal pada masing-masing perangkat:
- **Port `8080` (HTTP Server)**: Digunakan untuk endpoint REST:
  - `GET /ping` — Pengecekan status keaktifan perangkat.
  - `GET /info` — Pengambilan informasi nama perangkat & platform OS.
  - `POST /request` — Mengirimkan metadata permintaan transfer file untuk persetujuan.
  - `POST /receive` — Pengunggahan data file mentah via multipart stream.
- **Port `8081` (WebSocket)**: Digunakan untuk broadcasting teks clipboard secara dua arah dengan latensi rendah.
- **mDNS Service Type `_lshare._tcp`**: Digunakan untuk broadcasting & scanning perangkat aktif.

---

## ⚙️ Teknologi Stack

Aplikasi ini dibangun menggunakan library & framework terkini:
- **Core**: Flutter (Dart) dengan standar **null safety**.
- **State Management**: **Riverpod** (`flutter_riverpod`) untuk reaktivitas state.
- **UI Design System**: **Material 3** dengan font Outfit.
- **Networking**:
  - `shelf` & `shelf_router` (HTTP Server)
  - `shelf_web_socket` & `web_socket_channel` (WebSocket Clipboard Sync)
  - `bonsoir` (mDNS Service Discovery)
  - `dio` (HTTP Multipart File Upload Client)
- **Persistensi**: `shared_preferences` untuk riwayat log transfer dan pengaturan konfigurasi perangkat.
- **Utilitas**: `flutter_local_notifications` (Notifikasi unduhan selesai), `open_filex` (Membuka file), `permission_handler` (Manajemen perizinan Android).

---

## 🚀 Memulai

### Prasyarat
1. Flutter SDK terpasang di komputer Anda.
2. Perangkat Android (min SDK 21 / Android 5.0) atau emulator Android.
3. Hubungkan perangkat penguji ke **jaringan WiFi atau LAN yang sama**.

### Langkah Instalasi
1. Clone repositori ini ke komputer lokal Anda:
   ```bash
   git clone <repository-url>
   ```
2. Masuk ke direktori proyek:
   ```bash
   cd lshare
   ```
3. Unduh semua dependensi proyek:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi pada perangkat Android Anda:
   ```bash
   flutter run
   ```

---

## 🧪 Pengujian & Analisis Kode

Proyek ini telah dilengkapi dengan uji coba otomatis unit dan widget test untuk memastikan integritas logika bisnis aplikasi:
- Untuk menjalankan tes unit/widget secara lokal:
  ```bash
  flutter test
  ```
- Untuk menganalisis kepatuhan standar penulisan kode:
  ```bash
  flutter analyze
  ```

---

## 📝 Lisensi
Dibuat oleh **Syaifulloh R** - Mei 2026.
