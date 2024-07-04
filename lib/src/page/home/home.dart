import 'package:flutter/material.dart';

import '../../store/index.dart';
import 'settings.dart';
import 'passwords.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.store});

  static const routeName = "/";

  final Store store;

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  int _currentIndex = 0;
  late PageController _controller;

  final List<String> _labels = ["密码", "设置"];

  @override
  void initState() {
    _controller = PageController(initialPage: _currentIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        centerTitle: true,
        elevation: 1,
        title: Text(
          _labels[_currentIndex],
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      body: PageView(
        controller: _controller,
        onPageChanged: (index) {
          if (index != _currentIndex) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        children: [
          ListenableBuilder(
            listenable: widget.store.accounts,
            builder: (context, child) =>
                PasswordsPage(accountsContrller: widget.store.accounts),
          ),
          SettingsPage(store: widget.store)
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          _controller.animateToPage(index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.bounceInOut);
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
      ),
    );
  }
}
