import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../context/kdbx.dart';
import '../route.dart';
import '../../i18n.dart';
import '../../store/index.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
import '../../widget/infinite_rotate.dart';
import '../../util/common.dart';

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
    DetectionRoute(),
    SettingsRoute(),
  ];

  bool _enableRemoteSync = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Store.instance.settings.addListener(_settingsListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Store.instance.syncKdbx.init(KdbxProvider.of(context)!);
      _settingsListener();
    });
  }

  void _settingsListener() {
    if (_enableRemoteSync != Store.instance.settings.enableRemoteSync &&
        Store.instance.settings.enableRemoteSync) {
      final cycle = Store.instance.settings.remoteSyncCycle;
      final time = Store.instance.settings.lastSyncTime;
      if (cycle == null ||
          time == null ||
          time.add(cycle).isBefore(DateTime.now())) {
        Store.instance.syncKdbx.sync(context);
      }
    }
    _enableRemoteSync = Store.instance.settings.enableRemoteSync;
  }

  @override
  void dispose() {
    Store.instance.settings.removeListener(_settingsListener);
    super.dispose();
  }

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
            icon: const Icon(Icons.find_in_page_rounded),
            label: t.detection,
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

    final store = Store.instance;

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
            // leading: Padding(
            //   padding: const EdgeInsets.only(top: 8),
            //   child: Text(
            //     RpassInfo.appName,
            //     style: Theme.of(context).textTheme.titleLarge,
            //   ),
            // ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      store.syncKdbx,
                      store.settings,
                    ]),
                    builder: (context, _) {
                      return store.settings.enableRemoteSync &&
                              (store.syncKdbx.isSyncing ||
                                  store.syncKdbx.lastError != null)
                          ? InfiniteRotateWidget(
                              enabled: store.syncKdbx.isSyncing,
                              child: IconButton(
                                disabledColor:
                                    Theme.of(context).iconTheme.color,
                                color: !store.syncKdbx.isSyncing &&
                                        store.syncKdbx.lastError != null
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                                onPressed: !store.syncKdbx.isSyncing &&
                                        store.syncKdbx.lastError != null
                                    ? () {
                                        showError(store.syncKdbx.lastError);
                                      }
                                    : null,
                                icon: !store.syncKdbx.isSyncing &&
                                        store.syncKdbx.lastError != null
                                    ? const Icon(Icons.sync_problem)
                                    : const Icon(Icons.sync),
                              ),
                            )
                          : const SizedBox();
                    },
                  ),
                ),
              ),
            ),
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
                icon: const Icon(Icons.find_in_page_rounded),
                label: Text(t.detection),
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
  late SimpleSerialTimerTask _serialTimerTask;

  late final _observer = CallbackBindingObserver(
    didChangeAppLifecycleState: _didChangeAppLifecycleState,
  );

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(_observer);
    super.initState();
    bool verificationStart = false;
    _serialTimerTask = SimpleSerialTimerTask(
      TaskInfo(Duration.zero, () async {
        debugPrint("enter verificatino $verificationStart");
        if (verificationStart) return;
        verificationStart = true;
        await context.router.push(VerifyOwnerRoute());
        verificationStart = false;
      }),
      TaskInfo(Duration.zero, () {
        debugPrint("close kdbx, locked");
        KdbxProvider.setKdbx(context, null);
        context.router.replaceAll([LoadKdbxRoute()]);
      }),
    );
  }

  void _didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // 只有桌面端才回调 （inactive == bulr）?
        if (!Platform.isMacOS || !Platform.isWindows) {
          break;
        }
      case AppLifecycleState.hidden:
        if (Store.instance.settings.lockDelay != null) {
          _serialTimerTask.task1!.duration = Store.instance.settings.lockDelay!;
          _serialTimerTask.task2!.duration = Store.instance.settings.lockDelay!;
          debugPrint("start timer lock");
          _serialTimerTask.start();
        }
        break;
      case AppLifecycleState.resumed:
        debugPrint("cacnel timer lock");
        _serialTimerTask.cancel();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    _serialTimerTask.cancel();
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }
}
