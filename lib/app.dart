// lib/app.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_background/flutter_background.dart';
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
import 'core/services/discovery_service.dart';
import 'features/devices/devices_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/send/send_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/important_text/important_text_provider.dart';
import 'features/clipboard/clipboard_auth_provider.dart';

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
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _serverService = ref.read(serverServiceProvider);
    _clipboardService = ref.read(clipboardServiceProvider);
    _discoveryService = ref.read(discoveryServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Start the HTTP Server
      await _serverService.startServer();
      // Start discovery and broadcast
      final initialName = ref.read(deviceNameProvider);
      _discoveryService.startBroadcast(initialName, _serverService.port);
      ref.read(devicesProvider.notifier).startDiscovery();
      // Initialize Notification Service
      ref.read(notificationServiceProvider).initialize();
      // Start Clipboard Sync Service
      _clipboardService.startService();
      // Initialize Sharing Intent Listener
      _initSharingIntent();
      // Initialize Background execution service
      _initBackground().then((_) {
        if (Platform.isAndroid) {
          final bgRunning = ref.read(settingsProvider).backgroundRunning;
          if (bgRunning) {
            FlutterBackground.enableBackgroundExecution().then((success) {
              print('Background execution enabled on startup: $success');
            });
          }
        }
      });
      // Initialize PINs and Auth
      SharedPreferences.getInstance().then((prefs) {
        initImportantTextPin(ref, prefs);
        initClipboardAuth(ref, prefs);
      });
    });
  }

  Future<void> _initBackground() async {
    if (Platform.isAndroid) {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "LShare Server Aktif",
        notificationText: "Menunggu berkas masuk di jaringan lokal...",
        notificationImportance: AndroidNotificationImportance.normal,
        notificationIcon: AndroidResource(name: 'launcher_icon', defType: 'mipmap'),
      );
      
      bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
      print('FlutterBackground initialized: $success');
    }
  }

  void _initSharingIntent() {
    // For sharing media while the app is running in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedMedia(value);
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing media while the app was closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      _handleSharedMedia(value);
    });
  }

  void _handleSharedMedia(List<SharedMediaFile> media) async {
    if (media.isEmpty) return;
    
    final List<PlatformFile> platformFiles = [];
    for (var file in media) {
      final ioFile = File(file.path);
      if (await ioFile.exists()) {
        final size = await ioFile.length();
        final name = file.path.split(Platform.pathSeparator).last;
        platformFiles.add(PlatformFile(
          path: file.path,
          name: name,
          size: size,
        ));
      }
    }
    
    if (platformFiles.isNotEmpty) {
      ref.read(sendProvider.notifier).setSharedFiles(platformFiles);
      setState(() {
        _selectedIndex = 0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${platformFiles.length} file dari aplikasi luar terdeteksi. Pilih perangkat tujuan untuk mengirim.'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
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
        final serverService = ref.read(serverServiceProvider);
        await discoveryService.stopAll();
        await discoveryService.startBroadcast(next, serverService.port);
        ref.read(devicesProvider.notifier).startDiscovery();
      }
    });

    // Listen for background running settings changes
    ref.listen<bool>(
      settingsProvider.select((state) => state.backgroundRunning),
      (previous, next) async {
        if (Platform.isAndroid) {
          if (next) {
            final success = await FlutterBackground.enableBackgroundExecution();
            print("Background execution enabled dynamically: $success");
          } else {
            final success = await FlutterBackground.disableBackgroundExecution();
            print("Background execution disabled dynamically: $success");
          }
        }
      },
    );

    // Listen for incoming transfer requests to show bottom sheet
    ref.listen<List<TransferModel>?>(
      receiveProvider.select((state) => state.activeRequestBatch),
      (previous, next) {
        if (next != null && next.isNotEmpty) {
          showModalBottomSheet(
            context: context,
            isDismissible: false,
            enableDrag: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => ReceiveBottomSheet(transfers: next),
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
