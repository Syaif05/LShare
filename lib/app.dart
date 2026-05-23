// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_strings.dart';
import 'features/home/home_screen.dart';
import 'features/history/history_screen.dart';
import 'features/clipboard/clipboard_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/theme/app_theme.dart';
import 'core/services/server_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/clipboard_service.dart';
import 'core/models/transfer_model.dart';
import 'features/receive/receive_provider.dart';
import 'features/receive/receive_screen.dart';
import 'core/constants/app_constants.dart';
import 'core/services/discovery_service.dart';
import 'features/devices/devices_provider.dart';
import 'features/settings/settings_provider.dart';

class LShareApp extends StatelessWidget {
  const LShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;
  late ServerService _serverService;
  late ClipboardService _clipboardService;
  late DiscoveryService _discoveryService;

  @override
  void initState() {
    super.initState();
    _serverService = ref.read(serverServiceProvider);
    _clipboardService = ref.read(clipboardServiceProvider);
    _discoveryService = ref.read(discoveryServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start the HTTP Server
      _serverService.startServer();
      // Start discovery and broadcast
      final initialName = ref.read(deviceNameProvider);
      _discoveryService.startBroadcast(initialName, kServerPort);
      ref.read(devicesProvider.notifier).startDiscovery();
      // Initialize Notification Service
      ref.read(notificationServiceProvider).initialize();
      // Start Clipboard Sync Service
      _clipboardService.startService();
    });
  }

  @override
  void dispose() {
    // Stop the HTTP Server when app closes (though OS might kill it first)
    _serverService.stopServer();
    // Stop discovery and broadcast
    _discoveryService.stopAll();
    // Stop Clipboard Sync Service
    _clipboardService.stopService();
    super.dispose();
  }

  static const List<Widget> _screens = [
    HomeScreen(),
    HistoryScreen(),
    ClipboardScreen(),
    SettingsScreen(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: AppStrings.navHome,
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history_rounded),
      label: AppStrings.navHistory,
    ),
    NavigationDestination(
      icon: Icon(Icons.content_paste_outlined),
      selectedIcon: Icon(Icons.content_paste_rounded),
      label: AppStrings.navClipboard,
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: AppStrings.navSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen for device name changes to restart mDNS broadcast
    ref.listen<String>(deviceNameProvider, (previous, next) async {
      if (previous != next && next.isNotEmpty) {
        final discoveryService = ref.read(discoveryServiceProvider);
        await discoveryService.stopAll();
        await discoveryService.startBroadcast(next, kServerPort);
        ref.read(devicesProvider.notifier).startDiscovery();
      }
    });

    // Listen for incoming transfer requests to show bottom sheet
    ref.listen<TransferModel?>(
      receiveProvider.select((state) => state.activeRequest),
      (previous, next) {
        if (next != null) {
          showModalBottomSheet(
            context: context,
            isDismissible: false,
            enableDrag: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => ReceiveBottomSheet(transfer: next),
          );
        }
      },
    );

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _destinations,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
