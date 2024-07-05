import './settings/controller.dart';
import './verify/contrller.dart';
import './accounts/contrller.dart';

final class Store {
  static Store? _instance;

  factory Store() => _instance ?? Store._internal();

  Store._internal() {
    _instance = this;
  }

  final settings = SettingsController();
  final verify = VerifyController();
  final accounts = AccountsContrller();

  Future<void> loadStore() async {
    await settings.init(this);
    await verify.init(this);
    await accounts.init(this);
  }
}
