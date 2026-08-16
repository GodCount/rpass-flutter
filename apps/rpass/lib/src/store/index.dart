import 'kdbx/controller.dart';
import 'loacal_info/contrller.dart';
import 'settings/controller.dart';

export 'kdbx/controller.dart' show KdbxProviderListener;

sealed class Store {

  static final settings = SettingsController();
  static final localInfo = LocalInfoContrller();
  static final kdbx = KdbxController();

  static Future<void> loadStore() async {
    await settings.init();
    await localInfo.init();
  }
}

