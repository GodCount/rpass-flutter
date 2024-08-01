import '../rpass/account.dart';

abstract class BrowserAccount {
  const BrowserAccount();

  static List<BrowserAccount> fromCsv(String csv) {
    throw UnsupportedError("fromCsv static method.");
  }

  static List<Account> toAccounts(List<BrowserAccount> list) {
    throw UnsupportedError("toAccounts static method.");
  }

  static String toCsv(List<Account> list) {
    throw UnsupportedError("toCsv static method.");
  }

  Account toAccount();
}
