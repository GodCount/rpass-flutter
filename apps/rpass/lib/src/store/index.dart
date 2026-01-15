import 'loacal_info/contrller.dart';
import 'settings/controller.dart';
import 'sync_kdbx/controller.dart';

final class Store {
  Store._();

  static final Store _instance = Store._();

  static Store get instance => _instance;

  final settings = SettingsController();
  final localInfo = LocalInfoContrller();
  final syncKdbx = SyncKdbxController();

  Future<void> loadStore() async {
    await settings.init();
    await localInfo.init();
  }
}
