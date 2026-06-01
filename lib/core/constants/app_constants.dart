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

// TODO: Ganti URL dan Anon Key ini dengan kredensial Supabase Anda
const String kSupabaseUrl = 'https://apjeccqvqyucnwgyxvhb.supabase.co';
const String kSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFwamVjY3F2cXl1Y253Z3l4dmhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5NTU1MDYsImV4cCI6MjA5NTUzMTUwNn0.1t1buwgl7Cpe63GbKi-AEVznmx-dB7Fa9VFcQE0PQTY';
