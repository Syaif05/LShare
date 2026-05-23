import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize local notification settings.
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final filePath = response.payload;
        if (filePath != null && filePath.isNotEmpty) {
          try {
            await OpenFilex.open(filePath);
          } catch (e) {
            print('Error opening file from notification: $e');
          }
        }
      },
    );

    // Create a high importance channel for file transfers
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
        
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'lshare_transfers',
          'LShare File Transfers',
          description: 'Notifikasi untuk progress dan penyelesaian transfer file LShare',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _isInitialized = true;
  }

  /// Show a notification indicating that a file has been successfully received.
  Future<void> showTransferSuccess(String fileName, String filePath) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'lshare_transfers',
      'LShare File Transfers',
      channelDescription: 'Notifikasi untuk progress dan penyelesaian transfer file LShare',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      fileName.hashCode,
      'Transfer Selesai',
      '$fileName berhasil diterima.',
      details,
      payload: filePath,
    );
  }
}
