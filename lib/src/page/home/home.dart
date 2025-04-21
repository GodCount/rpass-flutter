import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rpass/src/util/common.dart';

import '../../context/store.dart';
import '../../i18n.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
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
      final args = data.argsAs<_HomeArgs>(orElse: () => _HomeArgs());
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
    with AutomaticKeepAliveClientMixin, BackgroundLock {
  final GlobalKey _globalKey = GlobalKey();

  final List<PageRouteInfo> _routes = [
    PasswordsRoute(),
    GroupsRoute(),
    SettingsRoute(),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AutoTabsRouter.pageView(
      scrollDirection: isDesktop ? Axis.vertical : Axis.horizontal,
      physics: isDesktop ? const NeverScrollableScrollPhysics() : null,
      routes: _routes,
      builder: (context, child, _) {
        return isDesktop
            ? _DesktopHomePage(key: _globalKey, child: child)
            : _MobileHomePage(key: _globalKey, child: child);
      },
    );
  }
}

class _MobileHomePage extends StatelessWidget {
  const _MobileHomePage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
  }
}

class _DesktopHomePage extends StatefulWidget {
  const _DesktopHomePage({super.key, required this.child});

  final Widget child;

  @override
  State<_DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<_DesktopHomePage>
    with SecondLevelRouteUtil<_DesktopHomePage> {
  @override
  void didCriticalChange({
    required bool oldIsIdeaSrceen,
    required bool oldIsSingleScreen,
  }) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final tabsRouter = AutoTabsRouter.of(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            minWidth: 64,
            minExtendedWidth: 132,
            extended: isIdeaSrceen,
            selectedIndex: tabsRouter.activeIndex,
            onDestinationSelected: tabsRouter.setActiveIndex,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.account_box_outlined),
                label: Text(t.password),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.groups_2_rounded),
                label: Text(t.group),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings),
                label: Text(t.setting),
              )
            ],
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: widget.child,
            ),
          )
        ],
      ),
    );
  }
}

// 后台触发锁定
mixin BackgroundLock on State<HomePage> {
  Timer? _timer;
  bool _verificationStart = false;

  late final _observer = CallbackBindingObserver(
      didChangeAppLifecycleState: _didChangeAppLifecycleState);

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(_observer);
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

  void _didChangeAppLifecycleState(AppLifecycleState state) {
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
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }
}
