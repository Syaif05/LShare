// lib/features/home/home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/network_utils.dart';

final localIpProvider = FutureProvider<String?>((ref) async {
  return NetworkUtils.getLocalIpAddress();
});

final homeProvider = Provider((ref) => const HomeState());

class HomeState {
  const HomeState();
}

