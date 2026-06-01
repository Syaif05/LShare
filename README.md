# 🚀 LShare — Local Share & Clipboard Sync v1.1.3

LShare adalah aplikasi multi-platform (Android, Windows, Linux) modern yang memungkinkan Anda melakukan transfer file (foto, video, dokumen) secara nirkabel antar perangkat yang terhubung ke jaringan WiFi/LAN lokal, serta menyinkronkan clipboard secara cloud via Supabase.

Di versi **v1.1.3**, aplikasi ini membawa desain **Soft Neo-Brutalism** yang tegas dan modern, serta peningkatan privasi menggunakan fitur Teks Penting ber-PIN lokal.

---

## ✨ Fitur Utama v1.1.3

### 📁 Grup Transfer (Soft Neo-Brutalism UI)
- **Transfer Batch Rapi**: Mengirim banyak file sekaligus tidak lagi membuat daftar file memanjang ke bawah. Semua pengiriman di batch yang sama dikelompokkan ke dalam satu "Bubble Grup" yang dapat di-klik (*expandable*).
- **Desain Modern**: Menggunakan estetika *Soft Neo-Brutalism* dengan border tegas, warna solid (seperti *Acid Yellow* dan *Neo Black*), dan efek *hard shadow* yang interaktif.

### 📋 Sinkronisasi Clipboard & Cloud (Supabase)
- **Real-time Sync**: Teks yang disalin akan tersinkronisasi antar perangkat menggunakan Supabase Realtime WebSocket.
- **Auto-Delete (Baru)**: Demi menghemat penyimpanan database, teks clipboard yang berumur lebih dari 7 hari otomatis dihapus saat aplikasi dijalankan.
- **Fitur Kunci / Lock (Baru)**: Terdapat ikon gembok pada tiap teks di riwayat clipboard. Teks yang dikunci **tidak akan** ikut terhapus oleh sistem *Auto-Delete*.

### 🔒 Teks Penting dengan PIN Lokal (Baru)
- **Teks Penting**: Menu khusus untuk menyimpan teks rahasia/penting yang tersinkronisasi di perangkat Anda.
- **Proteksi PIN Lokal**: Fitur ini dikunci dengan 4-digit PIN secara lokal. Jika perangkat Anda dipinjam, pengguna lain tidak bisa mengakses menu ini tanpa mengetahui PIN Anda.

### 🌐 Dukungan Multi-Platform (Baru)
- **Android**: Aplikasi sekarang di-build menggunakan format *split-per-abi*, memastikan ukuran APK instalasi jauh lebih kecil (~20MB) disesuaikan dengan arsitektur CPU masing-masing smartphone.
- **Windows & Linux Desktop**: LShare kini mendukung kompilasi dan dapat dijalankan di Windows maupun Kali Linux (serta distro Linux lainnya).

---

## 🛠️ Keputusan Teknis & Arsitektur

### Port Jaringan (Lokal)
- **Port `8080` (HTTP Server)**: Digunakan untuk REST API pertukaran file mentah.
  - `GET /ping` — Cek perangkat online.
  - `POST /request` — Meminta persetujuan transfer file masuk.
  - `POST /receive` — Pengunggahan multipart file mentah.
- **mDNS `_lshare._tcp`**: Broadcaster dan scanner perangkat lokal.

### Teknologi Stack
- **Framework**: Flutter (Dart) dengan standar **null safety**.
- **State Management**: **Riverpod** (`flutter_riverpod`).
- **Networking**: `shelf` & `dio` (HTTP Transfer), `bonsoir` (mDNS).
- **Database & Cloud**: Supabase (PostgreSQL & Realtime channel).
- **Utilitas**: `shared_preferences` (PIN & setting), `flutter_local_notifications`.

---

## 🚀 Memulai

### Prasyarat
1. Flutter SDK terpasang di komputer Anda.
2. Akun & Proyek Supabase.

### ⚠️ Konfigurasi Supabase (Wajib)
Jalankan script SQL berikut di menu SQL Editor pada dashboard Supabase Anda agar fitur Clipboard dan Teks Penting berfungsi:

```sql
-- 1. Kolom kunci untuk Clipboards
ALTER TABLE public.clipboards ADD COLUMN IF NOT EXISTS is_locked boolean DEFAULT false;

-- 2. Tabel Teks Penting
CREATE TABLE IF NOT EXISTS public.important_texts (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamp with time zone DEFAULT now(),
  text text NOT NULL,
  device_name text NOT NULL
);

-- 3. Aktifkan Realtime
alter publication supabase_realtime add table public.important_texts;
```

### Langkah Instalasi
1. Clone repositori ini:
   ```bash
   git clone <repository-url>
   cd lshare
   ```
2. Unduh dependensi:
   ```bash
   flutter pub get
   ```
3. Sesuaikan URL dan Anon Key Supabase Anda di `lib/core/constants/app_constants.dart`.
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

---

## 📦 Build untuk Produksi
- **Android**: `flutter build apk --split-per-abi`
- **Windows**: `flutter build windows`
- **Linux**: `flutter build linux` (Harus dijalankan di sistem operasi Linux)

---

## 📝 Lisensi
Dibuat oleh **Syaifulloh R** - Mei 2026.
