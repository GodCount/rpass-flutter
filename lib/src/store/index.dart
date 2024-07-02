import './settings/controller.dart';
import './settings/service.dart';
import './verify/contrller.dart';
import './verify/service.dart';
import './accounts/contrller.dart';
import './accounts/service.dart';

final class Store {
  static Store? _instance;

  factory Store() => _instance ?? Store._internal();

  Store._internal() {
    _instance = this;
  }

  final settings = SettingsController(SettingsService());
  final verify = VerifyController(VerifyService());
  final accounts = AccountsContrller(AccountsService());

  Future<void> loadStore() async {
    await settings.load();
    await verify.load();
  }
}
