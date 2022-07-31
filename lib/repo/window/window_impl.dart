import 'package:flutter/material.dart';
import 'package:h_ide/repo/window/window_repo.dart';
import 'package:window_manager/window_manager.dart';

class WindowImpl extends WindowRepo {
  @override
  Future init() async {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setFullScreen(true);
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
