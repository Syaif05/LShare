import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  /// Request necessary permissions for file transfer and mDNS discovery.
  static Future<bool> requestAllPermissions() async {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return true;
    }
    
    Map<Permission, PermissionStatus> statuses = await [
      // Network and WiFi are generally granted automatically, but we might need Location for WiFi name
      // Storage permissions
      Permission.storage,
      Permission.manageExternalStorage,
      // Notification permissions (for receive requests)
      Permission.notification,
    ].request();

    // Check if critical permissions are granted
    bool storageGranted = statuses[Permission.storage]?.isGranted == true || 
                          statuses[Permission.manageExternalStorage]?.isGranted == true || 
                          await Permission.storage.isGranted;
                          
    return storageGranted;
  }
}
