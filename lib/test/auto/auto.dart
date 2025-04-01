import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class MetricsBindingObserver extends WidgetsBindingObserver {
  MetricsBindingObserver({required VoidCallback didChangeMetrics})
      : _didChangeMetrics = didChangeMetrics;

  final VoidCallback _didChangeMetrics;

  @override
  void didChangeMetrics() {
    _didChangeMetrics();
  }
}

mixin SrceenSizeObserver<T extends StatefulWidget> on State<T> {
  final double ideaSrceenWidth = 814;
  final double singleSrceenWidth = 564;

  late final _srceenObserver =
      MetricsBindingObserver(didChangeMetrics: _didChangeMetrics);

  late Size srceenSize;
  bool isIdeaSrceen = false;
  bool isSingleScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_srceenObserver);
    _didChangeMetrics();
  }

  void _didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    srceenSize = view.physicalSize / view.devicePixelRatio;

    final oldIsIdeaSrceen = this.isIdeaSrceen;
    final oldIsSingleScreen = this.isSingleScreen;

    isIdeaSrceen = srceenSize.width > ideaSrceenWidth;
    isSingleScreen = srceenSize.width <= singleSrceenWidth;

    didSrceenSizeChange();

    if (oldIsIdeaSrceen != isIdeaSrceen ||
        oldIsSingleScreen != isSingleScreen) {
      didCriticalChange(
        oldIsIdeaSrceen: oldIsIdeaSrceen,
        oldIsSingleScreen: oldIsSingleScreen,
      );
    }
  }

  void didSrceenSizeChange() {}

  void didCriticalChange({
    required bool oldIsIdeaSrceen,
    required bool oldIsSingleScreen,
  }) {}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_srceenObserver);
    super.dispose();
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  AppState createState() => AppState();
}

final router = RootStackRouter.build(
  defaultRouteType: const RouteType.material(),
  routes: [
    NamedRouteDef(
      name: "HomePageRoute",
      path: "/home",
      initial: true,
      builder: (context, data) {
        return const HomePage();
      },
      children: [
        NamedRouteDef(
          name: 'UserListPageRoute',
          path: 'user_list',
          initial: true,
          builder: (context, data) {
            return const UserListPage(userGroupName: "UserList");
          },
          children: [
            CustomRoute(
              path: "user_info/:name",
              usesPathAsKey: true,
              page: PageInfo.builder(
                "UserInfoPageRoute",
                builder: (context, data) {
                  final name = data.params.getString("name", "null");
                  return UserInfoPage(name: name);
                },
              ),
              duration: const Duration(milliseconds: 500),
              transitionsBuilder: TransitionsBuilders.slideRightWithFade,
            ),
          ],
        ),
        NamedRouteDef(
          name: 'GroupsPageRoute',
          path: 'groups',
          builder: (context, data) {
            return const UserListPage(userGroupName: "Groups");
          },
          children: [
            CustomRoute(
              path: "user_info/:name",
              usesPathAsKey: true,
              page: PageInfo.builder(
                "UserInfoPageRoute",
                builder: (context, data) {
                  final name = data.params.getString("name", "null");
                  return UserInfoPage(name: name);
                },
              ),
              duration: const Duration(milliseconds: 500),
              transitionsBuilder: TransitionsBuilders.slideRightWithFade,
            ),
          ],
        ),
        NamedRouteDef(
          name: 'SettingsPageRoute',
          path: 'settings',
          builder: (context, data) {
            return const UserListPage(userGroupName: "Settings");
          },
          children: [
            CustomRoute(
              path: "user_info/:name",
              usesPathAsKey: true,
              page: PageInfo.builder(
                "UserInfoPageRoute",
                builder: (context, data) {
                  final name = data.params.getString("name", "null");
                  return UserInfoPage(name: name);
                },
              ),
              duration: const Duration(milliseconds: 500),
              transitionsBuilder: TransitionsBuilders.slideRightWithFade,
            ),
          ],
        ),
      ],
    ),
  ],
);

class AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.light(),
      routerConfig: router.config(
        navigatorObservers: () => [AutoRouteObserver()],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with SrceenSizeObserver<HomePage> {
  @override
  void didCriticalChange({
    required bool oldIsIdeaSrceen,
    required bool oldIsSingleScreen,
  }) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter.pageView(
      scrollDirection: isSingleScreen ? Axis.horizontal : Axis.vertical,
      physics: const NeverScrollableScrollPhysics(),
      routes: const [
        NamedRoute("UserListPageRoute"),
        NamedRoute("GroupsPageRoute"),
        NamedRoute("SettingsPageRoute"),
      ],
      builder: (context, child, _) {
        final tabsRouter = AutoTabsRouter.of(context);

        final isEmptyRouter =
            !context.router.navigationHistory.isPathActive("/user_info/");

        return Scaffold(
          body: !isSingleScreen
              ? Row(
                  children: [
                    NavigationRail(
                      minWidth: 64,
                      minExtendedWidth: 128,
                      extended: isIdeaSrceen,
                      selectedIndex: tabsRouter.activeIndex,
                      onDestinationSelected: tabsRouter.setActiveIndex,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainer,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.account_box_outlined),
                          label: Text("用户"),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.groups_2_rounded),
                          label: Text("组"),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings),
                          label: Text("设置"),
                        )
                      ],
                    ),
                    Expanded(
                      child: child,
                    )
                  ],
                )
              : child,
          bottomNavigationBar: isSingleScreen && isEmptyRouter
              ? BottomNavigationBar(
                  currentIndex: tabsRouter.activeIndex,
                  onTap: tabsRouter.setActiveIndex,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.account_box_outlined),
                      label: '用户',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.groups_2_rounded),
                      label: '组',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: '设置',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

class UserListPage extends StatefulWidget {
  const UserListPage({super.key, required this.userGroupName});

  final String userGroupName;

  @override
  State<UserListPage> createState() => UserListPageState();
}

class UserListPageState extends State<UserListPage>
    with SrceenSizeObserver<UserListPage> {
  bool isEmptyRouter = true;

  @override
  void initState() {
    super.initState();
    context.router.navigationHistory.addListener(_navigationHistory);
  }

  void _navigationHistory() {
    final isEmptyRouter =
        !context.router.navigationHistory.isPathActive("/user_info/");

    if (this.isEmptyRouter != isEmptyRouter) {
      this.isEmptyRouter = isEmptyRouter;
      setState(() {});
    }
  }

  @override
  void didCriticalChange({
    required bool oldIsIdeaSrceen,
    required bool oldIsSingleScreen,
  }) {
    if (oldIsSingleScreen != isSingleScreen) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    context.router.navigationHistory.removeListener(_navigationHistory);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final leftOffstage = isSingleScreen && !isEmptyRouter;
        final rightOffstage = isSingleScreen && isEmptyRouter;

        double leftWidth = (constraints.maxWidth / 2).clamp(250, 375);
        double rightWidth = constraints.maxWidth - leftWidth;

        if (!leftOffstage && rightOffstage) {
          leftWidth = constraints.maxWidth;
        } else if (!rightOffstage && leftOffstage) {
          rightWidth = constraints.maxWidth;
        }

        return Row(
          children: [
            Offstage(
              offstage: leftOffstage,
              child: SizedBox(
                width: leftWidth,
                child: _buildListWidget(context.router),
              ),
            ),
            Offstage(
              offstage: rightOffstage,
              child: SizedBox(
                width: rightWidth,
                child: IndexedStack(
                  index: isEmptyRouter ? 1 : 0,
                  children: const [AutoRouter(), EmptyPage()],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListWidget(StackRouter autoRouter) {
    return ListView.builder(
      itemCount: 100,
      itemBuilder: (context, i) {
        return ListTile(
          title: Text("User::${widget.userGroupName}::$i"),
          onTap: () {
            autoRouter.replace(
              NamedRoute(
                "UserInfoPageRoute",
                params: {
                  "name": i.toString(),
                },
              ),
            );
          },
        );
      },
    );
  }
}

class UserInfoPage extends StatelessWidget {
  const UserInfoPage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.teal,
        child: Center(
          child: Text('UserInfoPage::$name'),
        ),
      ),
    );
  }
}

class EmptyPage extends StatefulWidget {
  const EmptyPage({super.key});

  @override
  State<EmptyPage> createState() => EmptyPageState();
}

class EmptyPageState extends State<EmptyPage>
    with SrceenSizeObserver<EmptyPage> {
  @override
  void didSrceenSizeChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text("${srceenSize.width}x${srceenSize.height}"),
      ),
    );
  }
}
