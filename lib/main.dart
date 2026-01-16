import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:khuspus/Helper/pharseShortcut.dart';
import 'package:khuspus/Pages/homepage.dart';
import 'package:khuspus/Pages/launcher.dart';
import 'package:khuspus/db/database.dart';
import 'package:khuspus/db/db_init.dart';
import 'package:khuspus/db/queries/setting_queries.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  initDatabase();
  await AppDatabase.get();
  Future<void> openSettingsWindow() async {
    final ids = await WindowManagerPlus.getAllWindowManagerIds();

    for (final id in ids) {
      final win = WindowManagerPlus.fromWindowId(id);
      final title = await win.getTitle();

      if (title == 'Setting') {
        await win.show();
        await win.focus();
        return;
      }
    }

    // No existing settings window → create one
    await WindowManagerPlus.createWindow(['Setting']);
  }

  final SystemTray tray = SystemTray();

  Future<void> initTray() async {
    await tray.initSystemTray(title: "Khuspus", iconPath: "assets/icon.ico");

    tray.registerSystemTrayEventHandler((eventName) async {
      if (eventName == kSystemTrayEventClick) {
        await WindowManagerPlus.current.show();
        await WindowManagerPlus.current.focus();
      }
      if (eventName == kSystemTrayEventRightClick) {
        // Right click (Windows only)
        await tray.popUpContextMenu();
      }
    });
  }

  final windowId = args.isEmpty ? 0 : int.parse(args[0]);
  await WindowManagerPlus.ensureInitialized(windowId);

  final isLauncher = args.isEmpty || args.contains('Launcher');

  if (isLauncher) {
    await initTray();
  }

  final Menu menu = Menu();

  await menu.buildFrom([
    MenuItemLabel(
      label: 'Show Launcher',
      onClicked: (_) async {
        await WindowManagerPlus.current.show();
        await WindowManagerPlus.current.focus();
      },
    ),
    MenuItemLabel(
      label: 'Hide Launcher',
      onClicked: (_) async {
        await WindowManagerPlus.current.hide();
      },
    ),
    MenuItemLabel(
      label: 'Settings',
      onClicked: (_) async {
        await openSettingsWindow();
      },
    ),
    MenuItemLabel(
      label: 'Quit',
      onClicked: (_) async {
        await tray.destroy();
        exit(0);
      },
    ),
  ]);

  tray.setContextMenu(menu);

  final shortcut = await getSetting('launcherShortcut');

  final shortcutHotKey = await hotKeyFromString(shortcut!);

  await hotKeyManager.unregisterAll();
  Future<void> toggleLauncher() async {
    if (await WindowManagerPlus.current.isVisible()) {
      await WindowManagerPlus.current.hide();
    } else {
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    }
  }

  await hotKeyManager.register(
    // launcherHotKey,
    shortcutHotKey,
    keyDownHandler: (hotKey) async {
      // debugPrint('Ctrl + Shift + L pressed');
      // debugPrint('${shortcutHotKey.modifiers}');

      toggleLauncher();
    },
  );

  final isSettings = args.contains('Setting');

  if (isLauncher) {
    final launcherOptions = WindowOptions(
      size: const Size(800, 100),
      center: true,
      title: 'Launcher Window',
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
      skipTaskbar: true,
    );

    WindowManagerPlus.current.waitUntilReadyToShow(launcherOptions, () async {
      // await WindowManagerPlus.current.show();
      // await WindowManagerPlus.current.focus();
      await WindowManagerPlus.current.hide();
    });
  }

  if (isSettings) {
    final settingsOptions = WindowOptions(
      size: const Size(1000, 800),
      minimumSize: const Size(500, 500),
      center: true,
      title: 'Setting',
      titleBarStyle: TitleBarStyle.hidden,
      skipTaskbar: false,
    );
    WindowManagerPlus.current.waitUntilReadyToShow(settingsOptions, () async {
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    });
  }

  runApp(MyApp(args: args));
}

class MyApp extends StatelessWidget {
  final List<String> args;
  const MyApp({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Khuspus',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: args.contains('Setting') ? HomePage() : LauncherScreen(),
    );
  }
}
