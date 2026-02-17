import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);

  // Create shared service instances
  final s3Service = S3Service();
  final profileStorage = ProfileStorageService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConnectionProvider(
            s3Service: s3Service,
            profileStorage: profileStorage,
          )..loadProfiles(),
        ),
        ChangeNotifierProvider(
          create: (_) => FileBrowserProvider(s3Service: s3Service),
        ),
        ChangeNotifierProvider(
          create: (_) => TransferProvider(s3Service: s3Service),
        ),
      ],
      child: const S3ManagerApp(),
    ),
  );
}

class S3ManagerApp extends StatefulWidget {
  const S3ManagerApp({super.key});

  @override
  State<S3ManagerApp> createState() => _S3ManagerAppState();
}

class _S3ManagerAppState extends State<S3ManagerApp> with WindowListener {
  final SystemTray _systemTray = SystemTray();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initSystemTray();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _systemTray.destroy();
    super.dispose();
  }

  String _getTrayIconPath() {
    if (Platform.isWindows) {
      return 'assets/app_icon.ico';
    } else if (Platform.isMacOS) {
      return '../assets/app_icon.png';
    } else {
      return 'assets/app_icon.png';
    }
  }

  Future<void> _initSystemTray() async {
    try {
      await _systemTray.initSystemTray(
        iconPath: _getTrayIconPath(),
        toolTip: 'MinIO Desktop Client',
      );

      final menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(
          label: 'Show',
          onClicked: (_) async {
            await windowManager.show();
            await windowManager.focus();
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Quit',
          onClicked: (_) async {
            await windowManager.setPreventClose(false);
            await windowManager.close();
          },
        ),
      ]);
      await _systemTray.setContextMenu(menu);

      _systemTray.registerSystemTrayEventHandler((eventName) async {
        if (eventName == kSystemTrayEventClick ||
            eventName == kSystemTrayEventDoubleClick) {
          await windowManager.show();
          await windowManager.focus();
        } else if (eventName == kSystemTrayEventRightClick) {
          await _systemTray.popUpContextMenu();
        }
      });
    } catch (e) {}
  }

  // Close-Button goes to tray instead of closing the app
  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinIO Desktop Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ConnectionScreen(),
    );
  }
}
