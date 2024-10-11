

import './settings/controller.dart';
import 'loacal_info/contrller.dart';


final class Store {
  static Store? _instance;

  factory Store() => _instance ?? Store._internal();

  Store._internal() {
    _instance = this;
  }

  final settings = SettingsController();
  final localInfo = LocalInfoContrller();

  Future<void> loadStore() async {
    await settings.init(this);
    await localInfo.init(this);
  }
}
