import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import './store/index.dart';
import 'context/biometric.dart';
import 'route.dart';
import 'theme/theme.dart';
import 'i18n.dart';
import 'util/common.dart';

// ignore: unused_element
final _logger = Logger("mobile:app");

/// 导航路由时关闭输入焦点
/// 在移动端，阻止软键盘错误弹出
class UnfocusNavigatorRoute extends NavigatorObserver {
  UnfocusNavigatorRoute();

  @override
  void didPush(route, previousRoute) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPop(route, previousRoute) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didRemove(route, previousRoute) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didReplace({newRoute, oldRoute}) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

final RootStackRouter router = createAutoRoute();

class RpassApp extends StatelessWidget {
  const RpassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Biometric(
      child: ListenableBuilder(
        listenable: Store.settings,
        builder: (context, child) {
          final themeSeedColor =
              Store.settings.useKdbxSeedColor && Store.kdbx.meta?.color != null
              ? Store.kdbx.meta!.color!
              : Store.settings.themeSeedColor;

          return MaterialApp.router(
            restorationScopeId: 'app',
            theme: theme(Brightness.light, themeSeedColor),
            darkTheme: theme(Brightness.dark, themeSeedColor),
            themeMode: Store.settings.themeMode,
            locale: Store.settings.locale,
            localizationsDelegates: I18n.localizationsDelegates,
            supportedLocales: I18n.supportedLocales,
            routerConfig: router.config(
              navigatorObservers: () => [
                if (kIsMobile) UnfocusNavigatorRoute(),
              ],
            ),
          );
        },
      ),
    );
  }
}
