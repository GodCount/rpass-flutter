import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../context/store.dart';
import '../../i18n.dart';
import '../page.dart';
import 'groups.dart';
import 'settings.dart';
import 'passwords.dart';

final _logger = Logger("page:home");

class Home extends StatefulWidget {
  const Home({super.key});

  static const routeName = "/home";

  static HomeState? of(BuildContext context) {
    HomeState? home;
    if (context is StatefulElement && context.state is HomeState) {
      home = context.state as HomeState;
    }

    home = home ?? context.findAncestorStateOfType<HomeState>();

    return home;
  }

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home>
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
        await Navigator.of(context).pushNamed(VerifyOwnerPage.routeName);
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

  void toPasswordPageSearch(String text) async {
    // await _controller.animateToPage(
    //   0,
    //   duration: const Duration(milliseconds: 300),
    //   curve: Curves.easeIn,
    // );
    // _searchController.text = text;
  }

  @override
  void dispose() {
    _cancelTimer();
    // _controller.dispose();
    // _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AutoTabsRouter.pageView(
      scrollDirection: Axis.horizontal,
      routes: const [
        NamedRoute("PasswordsPage"),
        NamedRoute("GroupsPage"),
        NamedRoute("SettingsPage"),
      ],
      builder: (context, child, _) {
        final t = I18n.of(context)!;

        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: context.tabsRouter.activeIndex,
            onTap: context.tabsRouter.setActiveIndex,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.account_box_outlined),
                label: t.password,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.groups_2_rounded),
                label: t.group,
              ),
              BottomNavigationBarItem(
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

class _MyBottomNavigationBar extends StatefulWidget {
  const _MyBottomNavigationBar({
    required this.controller,
  });

  final PageController controller;

  @override
  State<StatefulWidget> createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<_MyBottomNavigationBar> {
  int get _pageIndex =>
      widget.controller.positions.isNotEmpty && widget.controller.page != null
          ? widget.controller.page!.round()
          : 0;

  late int _index;

  @override
  void initState() {
    _index = _pageIndex;
    widget.controller.addListener(() {
      if (_pageIndex != _index) {
        setState(() {
          _index = _pageIndex;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return NavigationBar(
      selectedIndex: _index,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      animationDuration: const Duration(milliseconds: 300),
      onDestinationSelected: (value) async {
        widget.controller.animateToPage(
          value,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      },
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
    );
  }
}
