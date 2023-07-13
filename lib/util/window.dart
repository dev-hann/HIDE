import 'package:window_manager/window_manager.dart';

class Window {
  Window._();

  static Window? _instance;

  static Window get instance {
    return _instance ??= Window._();
  }

  Future init() async {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
