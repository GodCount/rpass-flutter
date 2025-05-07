import 'dart:io';

import 'package:auto_route/auto_route.dart';

import 'page/route.dart';
import 'context/kdbx.dart';
import 'page/home/route_wrap.dart';
import 'store/index.dart';
import 'util/common.dart';

final skipAuthGuard = [
  LoadKdbxRoute.name,
  InitialRoute.name,
  // 初始化时从外部导入 kdbx
  LoadExternalKdbxRoute.name,
  AuthRemoteFsRoute.name,
  ImportRemoteKdbxRoute.name,
];

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final kdbx = KdbxProvider.of(resolver.context);
    if (kdbx == null && !skipAuthGuard.contains(resolver.routeName)) {
      resolver.redirectUntil(
        Store.instance.localInfo.localKdbxFileExists
            ? LoadKdbxRoute()
            : InitialRoute(),
        replace: true,
      );
    } else {
      resolver.next();
    }
  }
}

RootStackRouter _createMobileAutoRoute() {
  return RootStackRouter.build(
    // TODO! FlutterFragmentActivity 暂不支持预测返回，但根路由的预测返回能正常生效
    // https://github.com/flutter/flutter/issues/149753
    defaultRouteType: Platform.isAndroid
        ? const RouteType.material(enablePredictiveBackGesture: true)
        : const RouteType.cupertino(),
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
        path: "/manage_group_entry/:uuid",
        page: ManageGroupEntryRoute.page,
      ),
      AutoRoute(
        path: "/edit_account/:uuid",
        page: EditAccountRoute.page,
      ),
      AutoRoute(
        path: "/look_account/:uuid",
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
      AutoRoute(
        path: "/sync_account",
        page: SyncAccountRoute.page,
      ),
      AutoRoute(
        path: "/auth_remote_fs/:type",
        page: AuthRemoteFsRoute.page,
      ),
      AutoRoute(
        path: "/import_remote_file",
        page: ImportRemoteKdbxRoute.page,
      ),
    ],
  );
}

RootStackRouter _createDesktopAutoRoute() {
  return RootStackRouter.build(
    defaultRouteType: const RouteType.cupertino(),
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
            children: [
              NamedRouteDef(
                name: "EmptyPageRoute",
                initial: true,
                path: "empty",
                builder: (_, __) {
                  return const EmptyPage();
                },
              ),
              AutoRoute(
                path: "edit_account/:uuid",
                page: EditAccountRoute.page,
              ),
              AutoRoute(
                path: "look_account/:uuid",
                page: LookAccountRoute.page,
              ),
            ],
          ),
          AutoRoute(
            path: "groups",
            page: GroupsRoute.page,
            children: [
              NamedRouteDef(
                name: "EmptyPageRoute",
                initial: true,
                path: "empty",
                builder: (_, __) {
                  return const EmptyPage();
                },
              ),
              AutoRoute(
                path: "manage_group_entry/:uuid",
                page: ManageGroupEntryRoute.page,
              ),
            ],
          ),
          AutoRoute(
            path: "settings",
            page: SettingsRoute.page,
            children: [
              NamedRouteDef(
                name: "EmptyPageRoute",
                initial: true,
                path: "empty",
                builder: (_, __) {
                  return const EmptyPage();
                },
              ),
              AutoRoute(
                path: "recycle_bin",
                page: RecycleBinRoute.page,
              ),
              AutoRoute(
                path: "change_locale",
                page: ChangeLocaleRoute.page,
              ),
              AutoRoute(
                path: "more_security",
                page: MoreSecurityRoute.page,
              ),
              AutoRoute(
                path: "export_account",
                page: ExportAccountRoute.page,
              ),
              AutoRoute(
                path: "import_account",
                page: ImportAccountRoute.page,
              ),
              AutoRoute(
                path: "kdbx_setting",
                page: KdbxSettingRoute.page,
              ),
              AutoRoute(
                path: "sync_account",
                page: SyncAccountRoute.page,
              ),
            ],
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
        path: "/auth_remote_fs/:type",
        page: AuthRemoteFsRoute.page,
      ),
      AutoRoute(
        path: "/import_remote_kdbx",
        page: ImportRemoteKdbxRoute.page,
      ),
    ],
  );
}

RootStackRouter createAutoRoute() {
  return isDesktop ? _createDesktopAutoRoute() : _createMobileAutoRoute();
}
