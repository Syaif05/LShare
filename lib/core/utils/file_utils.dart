import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static const _channel = MethodChannel('com.syaifulloh.lshare/file_utils');

  /// Opens the public Downloads folder or internal LShare directory.
  static Future<void> openDownloadsFolder() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openDownloadsFolder');
      } catch (e) {
        print('Error calling openDownloadsFolder MethodChannel: $e');
        final saveDir = await getSaveDirectory();
        await OpenFilex.open(saveDir.path);
      }
    } else {
      final saveDir = await getSaveDirectory();
      await OpenFilex.open(saveDir.path);
    }
  }

  /// Gets the directory where received files will be saved.
  /// Typically Android/data/com.syaifulloh.lshare/files/Downloads/LShare or similar,
  /// but we'll try to use the public Downloads directory if possible.
  static Future<Directory> getSaveDirectory() async {
    Directory? directory;
    
    if (Platform.isAndroid) {
      // Try to get external storage download directory
      directory = Directory('/storage/emulated/0/Download/LShare');
      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } catch (e) {
          // Fallback if permission is denied
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            directory = Directory('${directory.path}/LShare');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          }
        }
      }
    } else {
      // Fallback for non-Android platforms
      final baseDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      directory = Directory('${baseDir.path}/LShare');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
    
    return directory ?? Directory.systemTemp;
  }

  /// Formats bytes into a human-readable string (e.g., "1.2 MB").
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
