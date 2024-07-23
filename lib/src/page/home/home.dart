import 'package:flutter/material.dart';

import '../../store/index.dart';
import 'settings.dart';
import 'passwords.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.store});

  static const routeName = "/home";

  final Store store;

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> with AutomaticKeepAliveClientMixin {
  late PageController _controller;

  @override
  bool get wantKeepAlive => true;

  bool _initDenrypted = false;

  @override
  void initState() {
    _controller = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_initDenrypted) {
      widget.store.accounts.initDenrypt().then(
            (value) => setState(() {
              _initDenrypted = true;
            }),
          );
    }

    return Scaffold(
      body: _initDenrypted
          ? PageView(
              controller: _controller,
              children: [
                PasswordsPage(accountsContrller: widget.store.accounts),
                SettingsPage(store: widget.store)
              ],
            )
          : const Center(child: Text("解密中...")),
      bottomNavigationBar: _initDenrypted
          ? _MyBottomNavigationBar(controller: _controller)
          : null,
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
    return NavigationBar(
      selectedIndex: _index,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      animationDuration: const Duration(milliseconds: 300),
      onDestinationSelected: (value) async {
        widget.controller.animateToPage(
          value,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.account_box_outlined),
          label: "密码",
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: "设置",
        )
      ],
    );
  }
}
