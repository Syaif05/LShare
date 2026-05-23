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
