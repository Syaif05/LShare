#!/bin/bash

echo "==============================================="
echo "   LShare Linux Desktop Setup & Build Script   "
echo "==============================================="

# 1. Update and install requirements
echo "[1/4] Menginstall dependensi Flutter Linux (membutuhkan akses sudo)..."
sudo apt-get update
sudo apt-get install -y clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev

# 2. Enable desktop support in flutter
echo "[2/4] Mengaktifkan dukungan Linux Desktop di Flutter..."
flutter config --enable-linux-desktop

# 3. Get dependencies
echo "[3/4] Mengambil dependensi project..."
flutter pub get

# 4. Build Release
echo "[4/4] Memulai proses Build Release Linux..."
flutter build linux --release

echo "==============================================="
echo "   Build Selesai!                              "
echo "   File eksekusi LShare ada di folder:         "
echo "   build/linux/x64/release/bundle/             "
echo "==============================================="
