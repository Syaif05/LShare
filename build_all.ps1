# PowerShell Script to build both Windows and Android formats for LShare
# Usage: Run .\build_all.ps1 in PowerShell

Clear-Host
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "          LSHARE FULL RELEASE BUILDER             " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Yellow

# Step 1: Cleaning previous builds
Write-Host "[1/4] Membersihkan cache build lama..." -ForegroundColor DarkCyan
flutter clean

# Step 2: Fetching dependencies
Write-Host "[2/4] Mengambil package dependencies..." -ForegroundColor DarkCyan
flutter pub get

# Step 3: Building Windows Application
Write-Host "[3/4] Memulai Build Windows Release..." -ForegroundColor Magenta
flutter build windows --release
if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Build Windows SUKSES!" -ForegroundColor Green
} else {
    Write-Host "ERROR: Build Windows GAGAL! Menghentikan proses." -ForegroundColor Red
    Exit $LASTEXITCODE
}

# Step 4: Building Android APK
Write-Host "[4/4] Memulai Build Android APK Release..." -ForegroundColor Magenta
flutter build apk --release --split-per-abi
if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Build Android SUKSES!" -ForegroundColor Green
} else {
    Write-Host "ERROR: Build Android GAGAL!" -ForegroundColor Red
    Exit $LASTEXITCODE
}

# Summary
Write-Host ""
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "         SEMUA FORMAT BERHASIL DI-BUILD!          " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "Lokasi Hasil Build:" -ForegroundColor Yellow
Write-Host "  Windows EXE  : C:\Users\syaif\Documents\Programan2\Flutter\lshare\build\windows\x64\runner\Release\lshare.exe" -ForegroundColor Green
Write-Host "  Android APK  : C:\Users\syaif\Documents\Programan2\Flutter\lshare\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Yellow
