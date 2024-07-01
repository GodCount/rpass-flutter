import './settings/controller.dart';
import './settings/service.dart';

final class Store {
  static Store? _instance;

  factory Store() => _instance ?? Store._internal();

  Store._internal() {
    _instance = this;
  }

  final settings = SettingsController(SettingsService());

  Future<void> loadStore() async {
    await settings.load();
  }
}
