import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../context/lan_fill_server.dart';
import '../route.dart';
import '../../i18n.dart';
import '../../store/index.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
import '../../widget/infinite_rotate.dart';
import '../../util/common.dart';

// ignore: unused_element
final _logger = Logger("page:home");

class _HomeArgs extends PageRouteArgs {
  _HomeArgs({super.key});
}

class HomeRoute extends PageRouteInfo<_HomeArgs> {
  HomeRoute({Key? key}) : super(name, args: _HomeArgs(key: key));

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
    with AutomaticKeepAliveClientMixin {
  final GlobalKey _globalKey = GlobalKey();

  final List<PageRouteInfo> _routes = [
    PasswordsRoute(),
    GroupsRoute(),
    SettingsRoute(),
  ];

  bool _enableRemoteSync = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    Store.settings.addListener(_settingsListener);
    Store.kdbx.syncController.initConfig();
    _settingsListener();
  }

  void _settingsListener() {
    if (_enableRemoteSync != Store.settings.enableRemoteSync &&
        Store.settings.enableRemoteSync) {
      final cycle = Store.settings.remoteSyncCycle;
      final time = Store.settings.lastSyncTime;
      if (cycle == null ||
          time == null ||
          time.add(cycle).isBefore(DateTime.now())) {
        Store.kdbx.syncController.sync(context);
      }
    }
    _enableRemoteSync = Store.settings.enableRemoteSync;
  }

  @override
  void dispose() {
    Store.settings.removeListener(_settingsListener);
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
            icon: const Icon(Icons.settings),
            label: t.setting,
          ),
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

    final lanFill = LanFillInherited.of(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            minWidth: 64,
            minExtendedWidth: 132,
            extended: isIdeaSrceen,
            selectedIndex: tabsRouter.activeIndex,
            onDestinationSelected: tabsRouter.setActiveIndex,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            trailingAtBottom: true,
            // leading: Padding(
            //   padding: const EdgeInsets.only(top: 8),
            //   child: Text(
            //     RpassInfo.appName,
            //     style: Theme.of(context).textTheme.titleLarge,
            //   ),
            // ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  if (kIsDesktop && lanFill != null)
                    IconButton(
                      onPressed: lanFill.openQrCodeDialog,
                      icon: Icon(
                        lanFill.serverClosed
                            ? Icons.cast_connected
                            : Icons.connect_without_contact_rounded,
                      ),
                    ),
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      Store.kdbx.syncController,
                      Store.settings,
                    ]),
                    builder: (context, _) {
                      return Store.settings.enableRemoteSync &&
                              (Store.kdbx.syncController.isSyncing ||
                                  Store.kdbx.syncController.lastError != null)
                          ? InfiniteRotateWidget(
                              enabled: Store.kdbx.syncController.isSyncing,
                              child: IconButton(
                                disabledColor: Theme.of(
                                  context,
                                ).iconTheme.color,
                                color:
                                    !Store.kdbx.syncController.isSyncing &&
                                        Store.kdbx.syncController.lastError !=
                                            null
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                                onPressed:
                                    !Store.kdbx.syncController.isSyncing &&
                                        Store.kdbx.syncController.lastError !=
                                            null
                                    ? () {
                                        showError(
                                          Store.kdbx.syncController.lastError!,
                                        );
                                      }
                                    : null,
                                icon:
                                    !Store.kdbx.syncController.isSyncing &&
                                        Store.kdbx.syncController.lastError !=
                                            null
                                    ? const Icon(Icons.sync_problem)
                                    : const Icon(Icons.sync),
                              ),
                            )
                          : const SizedBox();
                    },
                  ),
                ],
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
                icon: const Icon(Icons.settings),
                label: Text(t.setting),
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
