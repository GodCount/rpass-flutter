import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../context/store.dart';
import '../../i18n.dart';
import '../../util/route.dart';
import '../route.dart';

final _logger = Logger("page:home");

class _HomeArgs extends PageRouteArgs {
  _HomeArgs({super.key});
}

class HomeRoute extends PageRouteInfo<_HomeArgs> {
  HomeRoute({
    Key? key,
  }) : super(
          name,
          args: _HomeArgs(key: key),
        );

  static const name = "HomeRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_HomeArgs>();
      return HomePage(key: args.key);
    },
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  Timer? _timer;
  bool _verificationStart = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  void _startTimer() {
    final settings = StoreProvider.of(context).settings;
    if (settings.lockDelay != null && !_verificationStart) {
      _cancelTimer();
      _timer = Timer(settings.lockDelay!, () async {
        _verificationStart = true;
        await context.router.push(VerifyOwnerRoute());
        _verificationStart = false;
      });
    }
  }

  void _cancelTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // 只有桌面端才回调 （inactive == bulr）?
        if (!Platform.isMacOS || !Platform.isWindows) {
          break;
        }
      case AppLifecycleState.hidden:
        _startTimer();
        break;
      case AppLifecycleState.resumed:
        _cancelTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AutoTabsRouter.pageView(
      scrollDirection: Axis.horizontal,
      routes: [
        PasswordsRoute(),
        GroupsRoute(),
        SettingsRoute(),
      ],
      builder: (context, child, _) {
        final t = I18n.of(context)!;

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: context.tabsRouter.activeIndex,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            onDestinationSelected: context.tabsRouter.setActiveIndex,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.account_box_outlined),
                label: t.password,
              ),
              NavigationDestination(
                icon: const Icon(Icons.groups_2_rounded),
                label: t.group,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings),
                label: t.setting,
              )
            ],
          ),
        );
      },
    );
  }
}
