import 'accounts/contrller.dart';
import 'verify/contrller.dart';

final class OldStore {
  static OldStore? _instance;

  factory OldStore() => _instance ?? OldStore._internal();

  OldStore._internal() {
    _instance = this;
  }

  final accounts = AccountsContrller();
  final verify = VerifyController();

  Future<void> clear() async {
    await accounts.clear();
    await verify.clear();
  }

  Future<void> loadStore() async {
    await accounts.init();
    await verify.init();
  }
}
