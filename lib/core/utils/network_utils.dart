import 'dart:io';

class NetworkUtils {
  /// Gets the local IPv4 address of the device (typically WiFi LAN IP).
  static Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Ignore link-local and loopback addresses
          if (!addr.isLoopback && !addr.isLinkLocal) {
            // Typically, we want addresses starting with 192.168.x.x, 10.x.x.x, or 172.16.x.x (private ranges)
            if (addr.address.startsWith('192.168.') || 
                addr.address.startsWith('10.') || 
                addr.address.startsWith('172.')) {
              return addr.address;
            }
          }
        }
      }
      
      // Fallback: return the first available address if private IP is not matched
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return null;
  }

  /// Checks if the device seems to have a local network connection.
  static Future<bool> isWifiConnected() async {
    final ip = await getLocalIpAddress();
    return ip != null && ip.isNotEmpty;
  }
}
