import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../component/highlight_text.dart';
import '../../context/store.dart';
import '../../i18n.dart';
import '../../model/rpass/account.dart';
import '../../util/common.dart';
import '../page.dart';
import '../../store/accounts/contrller.dart';

class PasswordsPage extends StatefulWidget {
  const PasswordsPage({super.key});

  @override
  State<PasswordsPage> createState() => PasswordsPageState();
}

class PasswordsPageState extends State<PasswordsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<Account> _accounts = [];
  String _searchText = "";

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      StoreProvider.of(context).accounts.addListener(_searchAccounts);
    });
    _searchAccounts();
    super.initState();
  }

  void _searchAccounts() {
    _accounts.clear();
    final store = StoreProvider.of(context);
    if (_searchText.isNotEmpty) {
      final searchText = _searchText.toLowerCase();
      _accounts.addAll(store.accounts.accountList.where((account) {
        var weight = account.domain.toLowerCase().contains(searchText) ? 1 : 0;
        weight += account.domainName.toLowerCase().contains(searchText) ? 1 : 0;
        weight += account.account.toLowerCase().contains(searchText) ? 1 : 0;
        weight += account.email.toLowerCase().contains(searchText) ? 1 : 0;
        weight += account.password.toLowerCase().contains(searchText) ? 1 : 0;
        weight +=
            account.description.toLowerCase().contains(searchText) ? 1 : 0;
        weight += account.labels.contains(searchText) ? 1 : 0;
        return weight > 0;
      }));
    } else {
      _accounts.addAll(store.accounts.accountList);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final store = StoreProvider.of(context);

    final mainColor = Theme.of(context).colorScheme.primaryContainer;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _AppBarTitleToSearch(
          itemCount: store.accounts.accountList.length,
          matchCount: _searchText.isNotEmpty ? _accounts.length : 0,
          onChanged: (text) {
            _searchText = text;
            _searchAccounts();
          },
        ),
      ),
      body: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: _accounts.length,
        separatorBuilder: (context, index) {
          return const SizedBox(
            height: 12,
          );
        },
        itemBuilder: (context, index) {
          return _OpenContainerPasswordItem(
            accountsContrller: store.accounts,
            account: _accounts[index],
            matchText: _searchText,
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
          return const EditAccountPage();
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

typedef OnInputChanged = void Function(String value);

class _AppBarTitleToSearch extends StatefulWidget {
  const _AppBarTitleToSearch({
    required this.onChanged,
    required this.itemCount,
    required this.matchCount,
  });

  final OnInputChanged onChanged;
  final int itemCount;
  final int matchCount;

  @override
  State<_AppBarTitleToSearch> createState() => _AppBarTitleToSearchState();
}

class _AppBarTitleToSearchState extends State<_AppBarTitleToSearch> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });

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
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _hasFocus = true;
        });
      },
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: false,
        ignorePointers: !_hasFocus,
        style: Theme.of(context).textTheme.bodySmall,
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
            child: _hasFocus || _controller.text.isNotEmpty
                ? Text(
                    t.search_match_count(widget.matchCount, widget.itemCount),
                  )
                : Text(t.password),
          ),
          prefixIcon: AnimatedOpacity(
            opacity: _hasFocus ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.search),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              _controller.clear();
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
    this.matchText,
  });

  final Account account;
  final AccountsContrller accountsContrller;
  final String? matchText;

  @override
  Widget build(BuildContext context) {
    final mainColor = Theme.of(context).colorScheme.surfaceContainerLow;

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
            accountId: account.id,
          );
        }
        return LookAccountPage(
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
          matchText: matchText,
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
  const _PasswordItem({
    required this.account,
    this.matchText,
    this.onTop,
    this.onLongPress,
  });

  final Account account;
  final String? matchText;
  final GestureTapCallback? onTop;
  final GestureLongPressCallback? onLongPress;

  @override
  State<_PasswordItem> createState() => _PasswordItemState();
}

class _PasswordItemState extends State<_PasswordItem> {
  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

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
      title: HighlightText(
        text: account.domainName,
        matchText: widget.matchText,
        style: Theme.of(context).textTheme.titleLarge,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: HighlightText(
              text: account.domain,
              matchText: widget.matchText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          _subtitleText(t.account_ab, account.account),
          _subtitleText(t.email_ab, account.email),
          _subtitleText(t.label_ab, account.labels.join(", ")),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              dateFormat(account.date),
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
    return HighlightText(
      prefixText: "$subLabel ",
      text: text,
      matchText: widget.matchText,
      style: Theme.of(context).textTheme.bodyMedium,
      prefixStyle: Theme.of(context).textTheme.titleMedium,
      overflow: TextOverflow.ellipsis,
    );
  }
}
