#!/bin/bash

echo "==============================================="
echo "   LShare macOS Desktop Setup & Build Script   "
echo "==============================================="

# 1. Enable desktop support in flutter
echo "[1/3] Mengaktifkan dukungan macOS Desktop di Flutter..."
flutter config --enable-macos-desktop

# 2. Get dependencies
echo "[2/3] Mengambil dependensi project..."
flutter pub get

# 3. Build Release
echo "[3/3] Memulai proses Build Release macOS..."
flutter build macos --release

echo "==============================================="
echo "   Build Selesai!                              "
echo "   Aplikasi LShare.app ada di folder:          "
echo "   build/macos/Build/Products/Release/         "
echo "==============================================="
