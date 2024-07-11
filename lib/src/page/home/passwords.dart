import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../model/account.dart';
import '../../util/common.dart';
import '../page.dart';
import '../../store/accounts/contrller.dart';

class PasswordsPage extends StatefulWidget {
  const PasswordsPage({super.key, required this.accountsContrller});

  final AccountsContrller accountsContrller;

  @override
  State<PasswordsPage> createState() => PasswordsPageState();
}

class PasswordsPageState extends State<PasswordsPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  late final Debouncer _debouncer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _debouncer = Debouncer();
    _controller.addListener(() {
      _debouncer.debounce(() {
        widget.accountsContrller.searchSort(_controller.text);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final accountList = widget.accountsContrller.accountList;

    final mainColor = Theme.of(context).colorScheme.primaryContainer;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _AppBarTitleToSearch(
          title: "密码",
          controller: _controller,
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.accountsContrller,
        builder: (context, child) {
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: accountList.length,
            separatorBuilder: (context, index) {
              return const SizedBox(
                height: 12,
              );
            },
            itemBuilder: (context, index) {
              return _OpenContainerPasswordItem(
                accountsContrller: widget.accountsContrller,
                account: accountList[index],
              );
            },
          );
        },
      ),
      floatingActionButton: OpenContainer(
        transitionType: ContainerTransitionType.fade,
        transitionDuration: const Duration(milliseconds: 600),
        openColor: mainColor,
        closedColor: mainColor,
        middleColor: mainColor,
        openBuilder: (BuildContext context, VoidCallback _) {
          return EditAccountPage(accountsContrller: widget.accountsContrller);
        },
        closedElevation: 6.0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return SizedBox(
            width: 56,
            height: 56,
            child: InkWell(
              onTap: openContainer,
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}

class _AppBarTitleToSearch extends StatefulWidget {
  const _AppBarTitleToSearch({required this.controller, required this.title});

  final TextEditingController controller;
  final String title;

  @override
  State<_AppBarTitleToSearch> createState() => _AppBarTitleToSearchState();
}

class _AppBarTitleToSearchState extends State<_AppBarTitleToSearch> {
  final FocusNode _focusNode = FocusNode();

  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _hasFocus) {
        setState(() {
          _hasFocus = false;
        });
      } else if (_focusNode.hasFocus) {
        setState(() {
          _hasFocus = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _hasFocus = true;
        });
      },
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: false,
        ignorePointers: !_hasFocus,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelStyle:
              !_hasFocus ? Theme.of(context).textTheme.titleLarge : null,
          label: AnimatedAlign(
            alignment: _hasFocus ? Alignment.centerLeft : Alignment.center,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInBack,
            onEnd: () {
              if (_hasFocus) {
                _focusNode.requestFocus();
              }
            },
            child: Text(_hasFocus ? "搜索" : "密码"),
          ),
          prefixIcon: AnimatedOpacity(
            opacity: _hasFocus ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.search),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              widget.controller.clear();
              _focusNode.unfocus();
            },
            icon: AnimatedOpacity(
              opacity: _hasFocus ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.close),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenContainerPasswordItem extends StatelessWidget {
  const _OpenContainerPasswordItem({
    required this.account,
    required this.accountsContrller,
  });

  final Account account;
  final AccountsContrller accountsContrller;

  @override
  Widget build(BuildContext context) {
    final mainColor = Theme.of(context).cardColor;

    bool isLogPress = false;

    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 600),
      tappable: false,
      openColor: mainColor,
      closedColor: mainColor,
      middleColor: mainColor,
      openBuilder: (BuildContext context, VoidCallback _) {
        if (isLogPress) {
          return EditAccountPage(
            accountsContrller: accountsContrller,
            accountId: account.id,
          );
        }
        return LookAccountPage(
          accountsContrller: accountsContrller,
          accountId: account.id,
        );
      },
      closedElevation: 2,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return _PasswordItem(
          account: account,
          onTop: () {
            isLogPress = false;
            openContainer();
          },
          onLongPress: () {
            isLogPress = true;
            openContainer();
          },
        );
      },
    );
  }
}

class _PasswordItem extends StatefulWidget {
  const _PasswordItem({required this.account, this.onTop, this.onLongPress});

  final Account account;
  final GestureTapCallback? onTop;
  final GestureLongPressCallback? onLongPress;

  @override
  State<_PasswordItem> createState() => _PasswordItemState();
}

class _PasswordItemState extends State<_PasswordItem> {
  @override
  Widget build(BuildContext context) {
    final Account account = widget.account;
    return ListTile(
      isThreeLine: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      leading: const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Icon(Icons.supervised_user_circle),
      ),
      title: Text(
        account.domainName,
        overflow: TextOverflow.ellipsis,
      ),
      titleTextStyle: Theme.of(context).textTheme.titleLarge,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              account.domain,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          _subtitleText("A", account.account),
          _subtitleText("E", account.email),
          _subtitleText("L", account.labels.join(", ")),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              account.date.toString(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onTap: widget.onTop,
      onLongPress: widget.onLongPress,
    );
  }

  Widget _subtitleText(String subLabel, String text) {
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        text: "$subLabel. ",
        style: Theme.of(context).textTheme.titleMedium,
        children: [
          TextSpan(
            text: text,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        ],
      ),
    );
  }
}