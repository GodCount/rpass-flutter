import 'package:flutter/material.dart';
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

class HomeState extends State<Home> with AutomaticKeepAliveClientMixin {
  final PageController _controller = PageController(initialPage: 0);
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void toPasswordPageSearch(String text) async {
    await _controller.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
    _searchController.text = text;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: PageView(
        controller: _controller,
        children: [
          PasswordsPage(searchController: _searchController),
          const GroupsPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: _MyBottomNavigationBar(controller: _controller),
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
