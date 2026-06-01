// lib/core/constants/app_constants.dart

const int kServerPort = 8080;
const int kWebSocketPort = 8081;
const String kMdnsServiceType = '_lshare._tcp';
const String kAppName = 'LShare';
const int kChunkSize = 1024 * 1024; // 1MB chunks
const Duration kDiscoveryTimeout = Duration(seconds: 5);
const Duration kConnectionTimeout = Duration(seconds: 10);
const int kMaxHistoryItems = 100;
const int kMaxClipboardHistory = 10;
const Duration kClipboardPollInterval = Duration(milliseconds: 500);
const Duration kReceiveTimeout = Duration(seconds: 30);

// Ciphertext of Supabase credentials (encrypted via AES-256 using the master PIN)
const String kEncryptedSupabaseUrl = '5YNPXflGcUiaxDh1LSJrtQ==:PSV7dSz4LYf8B21Hla0oLjKonVP7tFIHmvucHbOTE3fL8oFKHsBFgt8A7FuBiuJL';
const String kEncryptedSupabaseAnonKey = 'q9+3vVZVm5goshFwWPPjnQ==:O5kERmzs9YoPdcFA5R7L7cXWxneZEtRAqbd9wxjjhhs5uJOkmPEQ4adoweaXE5f7mcC+CI6t/voyfNXBRI8fpasphJkpYcgCkITP+craBJu5K8X/VRRR48Kd/Xy3Qz6o/W1Uhn9/Goz52gE7XddqAAg+d5rENTvle6sppBhz6IG6UxjEOW7R/x5EcmUeHMnhWzAungM59J/xHWVgMExomH3BJXTQpyalU7agOltM7BvQYnyaC2a3AVoVjHX9kFPvpj0iMqPxmkMXXwvktGAhAtuEK91ULVFXDKYJwJNADF0=';
