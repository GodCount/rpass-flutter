import 'package:auto_route/auto_route.dart';

import './page/route.dart';
import 'context/kdbx.dart';
import 'context/store.dart';

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final kdbx = KdbxProvider.of(resolver.context);
    if (kdbx == null &&
        ![LoadKdbxRoute.name, InitialRoute.name].contains(resolver.routeName)) {
      final store = StoreProvider.of(resolver.context);
      resolver.redirectUntil(
        store.localInfo.localKdbxFileExists ? LoadKdbxRoute() : InitialRoute(),
        replace: true,
      );
    } else {
      resolver.next();
    }
  }
}

RootStackRouter createAutoRoute() {
  return RootStackRouter.build(
    // TODO! FlutterFragmentActivity 暂不支持预测返回，但根路由的预测返回能正常生效
    // https://github.com/flutter/flutter/issues/149753
    defaultRouteType: const RouteType.material(enablePredictiveBackGesture: true),
    guards: [AuthGuard()],
    routes: [
      AutoRoute(
        path: "/initial",
        page: InitialRoute.page,
      ),
      AutoRoute(
        path: "/load_kdbx",
        page: LoadKdbxRoute.page,
      ),
      AutoRoute(
        path: "/home",
        page: HomeRoute.page,
        initial: true,
        children: [
          AutoRoute(
            path: "passwords",
            page: PasswordsRoute.page,
          ),
          AutoRoute(
            path: "groups",
            page: GroupsRoute.page,
          ),
          AutoRoute(
            path: "settings",
            page: SettingsRoute.page,
          ),
        ],
      ),
      AutoRoute(
        path: "/load_external_kdbx",
        page: LoadExternalKdbxRoute.page,
      ),
      AutoRoute(
        path: "/modify_password",
        page: ModifyPasswordRoute.page,
      ),
      AutoRoute(
        path: "/verify_owner",
        page: VerifyOwnerRoute.page,
      ),
      AutoRoute(
        path: "/select_icon",
        page: SelectIconRoute.page,
      ),
      AutoRoute(
        path: "/recycle_bin",
        page: RecycleBinRoute.page,
      ),
      AutoRoute(
        path: "/kdbx_setting",
        page: KdbxSettingRoute.page,
      ),
      AutoRoute(
        path: "/manage_group_entry",
        page: ManageGroupEntryRoute.page,
      ),
      AutoRoute(
        path: "/edit_account",
        page: EditAccountRoute.page,
      ),
      AutoRoute(
        path: "/look_account",
        page: LookAccountRoute.page,
      ),
      AutoRoute(
        path: "/edit_notes",
        page: EditNotesRoute.page,
      ),
      AutoRoute(
        path: "/gen_password",
        page: GenPasswordRoute.page,
      ),
      AutoRoute(
        path: "/scanner_code",
        page: QrCodeScannerRoute.page,
      ),
      AutoRoute(
        path: "/change_locale",
        page: ChangeLocaleRoute.page,
      ),
      AutoRoute(
        path: "/export_account",
        page: ExportAccountRoute.page,
      ),
      AutoRoute(
        path: "/import_account",
        page: ImportAccountRoute.page,
      ),
      AutoRoute(
        path: "/more_security",
        page: MoreSecurityRoute.page,
      ),
    ],
  );
}
