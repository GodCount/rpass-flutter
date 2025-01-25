import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:logging/logging.dart';

import '../../i18n.dart';
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

class HomeState extends State<Home> {
  final PageController _controller = PageController(initialPage: 0);
  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigate = GlobalKey<NavigatorState>();

  final List<bool> _dividerHover = [false, false];

  final ResizableController _resizableController = ResizableController();

  bool _extended = false;

  @override
  void initState() {
    super.initState();
    // _resizableController.addListener(() {
    //   final extended = _resizableController.pixels.isNotEmpty &&
    //       _resizableController.pixels[0] > 64;
    //   if (extended != _extended) {
    //     _extended = extended;
    //     // WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
    //   }
    // });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _resizableController.dispose();
    super.dispose();
  }

  void toPasswordPageSearch(String text) async {
    // TODO!
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        _navigate.currentState?.pushNamed('/password');
        break;
      case 1:
        _navigate.currentState?.pushNamed('/groups');
        break;
      case 2:
        _navigate.currentState?.pushNamed('/settings');
        break;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // void _dividerInput(int index) {
  //   if (_dividerHover[index]) return;
  //   _dividerHover[index] = true;
  //   setState(() {});
  // }

  // void _dividerOutput(int index) {
  //   if (!_dividerHover[index]) return;
  //   _dividerHover[index] = false;
  //   setState(() {});
  // }

  (ResizableDivider, ResizableDivider) _createResizableDivider() {
    final color =
        !_dividerHover[0] ? Theme.of(context).primaryColor : Colors.transparent;
    return (
      ResizableDivider(
        color: color,
        thickness: 4,
        padding: 4,
        // onHoverEnter: () => _dividerInput(0),
        // onHoverExit: () => _dividerOutput(0),
        // onTapDown: () => _dividerInput(0),
        // onTapUp: () => _dividerOutput(0),
      ),
      ResizableDivider(
        color: color,
        thickness: 4,
        padding: 4,
        // onHoverEnter: () => _dividerInput(1),
        // onHoverExit: () => _dividerOutput(1),
        // onTapDown: () => _dividerInput(1),
        // onTapUp: () => _dividerOutput(1),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final dividers = _createResizableDivider();

    return Scaffold(
      body: ResizableContainer(
        direction: Axis.horizontal,
        controller: _resizableController,
        children: [
          ResizableChild(
            size: const ResizableSize.shrink(min: 64, max: 192),
            divider: dividers.$1,
            child: NavigationRail(
              minWidth: 64,
              extended: _extended,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
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
          ),
          ResizableChild(
            size: const ResizableSize.expand(min: 350),
            divider: dividers.$2,
            child: SizedBox(
              width: 350,
              child: Navigator(
                key: _navigate,
                initialRoute: '/password',
                onGenerateRoute: (RouteSettings settings) {
                  WidgetBuilder builder;

                  switch (settings.name) {
                    case '/settings':
                      builder = (BuildContext _) => const SettingsPage();
                      break;
                    case '/groups':
                      builder = (BuildContext _) => const GroupsPage();
                      break;
                    case "/password":
                    default:
                      builder = (BuildContext _) => const PasswordsPage();
                  }

                  return MaterialPageRoute(
                    builder: builder,
                    settings: settings,
                  );
                },
              ),
            ),
          ),
          // ResizableChild(
          //   size: const ResizableSize.expand(),
          //   child: ColoredBox(
          //     color: Theme.of(context).colorScheme.tertiaryContainer,
          //     child: const SizeLabel(),
          //   ),
          // ),
        ],
      ),
      // bottomNavigationBar: _MyBottomNavigationBar(controller: _controller),
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
