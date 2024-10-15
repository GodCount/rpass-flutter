import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../old/store/index.dart';
import '../../widget/extension_state.dart';
import 'groups.dart';
import 'settings.dart';
import 'passwords.dart';

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
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _initMigrate);
  }

  void _initMigrate() async {
    final oldStore = OldStore();
    if (oldStore.accounts.accountList.isNotEmpty) {
      final kdbx = KdbxProvider.of(context)!;
      try {
        kdbx.import(OldRpassAdapter().import(oldStore.accounts.accountList));
        await kdbxSave(kdbx);
        await oldStore.clear();
        showToast("数据迁移完成");
        setState(() {});
      } catch (e) {
        showToast("迁移出现了意外情况! $e");
      }
    }
  }

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

    return OldStore().accounts.accountList.isEmpty
        ? Scaffold(
            body: PageView(
              controller: _controller,
              children: [
                PasswordsPage(searchController: _searchController),
                const GroupsPage(),
                const SettingsPage(),
              ],
            ),
            bottomNavigationBar:
                _MyBottomNavigationBar(controller: _controller),
          )
        : const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
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
        const NavigationDestination(
          icon: Icon(Icons.groups_2_rounded),
          label: "分组",
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings),
          label: t.setting,
        )
      ],
    );
  }
}
