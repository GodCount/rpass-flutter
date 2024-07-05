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

    print("build home");

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
          : const Center(child: Text("loading...")),
      bottomNavigationBar: _initDenrypted
          ? MyBottomNavigationBar(
              controller: _controller,
            )
          : null,
    );
  }
}

class MyBottomNavigationBar extends StatefulWidget {
  const MyBottomNavigationBar({super.key, required this.controller});

  final PageController controller;

  @override
  State<StatefulWidget> createState() => MyBottomNavigationBarState();
}

class MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  int _index = 0;
  late final PageController _controller;

  @override
  void initState() {
    _controller = widget.controller;

    _controller.addListener(() {
      if (_controller.page!.round() != _index) {
        setState(() {
          _index = _controller.page!.round();
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _index,
      onTap: (index) {
        widget.controller.animateToPage(index,
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.supervised_user_circle,
          ),
          label: "密码",
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.settings,
          ),
          label: "设置",
        ),
      ],
    );
  }
}
