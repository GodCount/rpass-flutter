import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/common.dart';
import '../page.dart';

class PasswordsPage extends StatefulWidget {
  const PasswordsPage({super.key, this.searchController});

  final TextEditingController? searchController;

  @override
  State<PasswordsPage> createState() => PasswordsPageState();
}

class PasswordsPageState extends State<PasswordsPage>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _searchController;

  @override
  bool get wantKeepAlive => true;

  final KbdxSearchHandler _kbdxSearchHandler = KbdxSearchHandler();
  final List<KdbxEntry> _totalEntry = [];

  @override
  void initState() {
    _searchController = widget.searchController ?? TextEditingController();
    _searchController.addListener(_searchAccounts);
    Future.delayed(Duration.zero, () {
      KdbxProvider.of(context)!.addListener(_onKdbxSave);
    });
    _searchAccounts();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    KdbxProvider.of(context)!.removeListener(_onKdbxSave);
    super.dispose();
  }

  void _onKdbxSave() {
    final kdbx = KdbxProvider.of(context)!;
    _kbdxSearchHandler.setFieldOther(kdbx.fieldStatistic.customFields);
    _searchAccounts();
  }

  void _searchAccounts() {
    _totalEntry.clear();
    final kdbx = KdbxProvider.of(context)!;

    _totalEntry.addAll(_kbdxSearchHandler.search(
      _searchController.text,
      kdbx.totalEntry,
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final kdbx = KdbxProvider.of(context)!;

    final mainColor = Theme.of(context).colorScheme.primaryContainer;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _AppBarTitleToSearch(
          controller: _searchController,
          itemCount: kdbx.totalEntry.length,
          matchCount:
              _searchController.text.isNotEmpty ? _totalEntry.length : 0,
        ),
      ),
      body: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: _totalEntry.length,
        separatorBuilder: (context, index) {
          return const SizedBox(
            height: 12,
          );
        },
        itemBuilder: (context, index) {
          return _OpenContainerPasswordItem(kdbxEntry: _totalEntry[index]);
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

class _AppBarTitleToSearch extends StatefulWidget {
  const _AppBarTitleToSearch({
    required this.controller,
    required this.itemCount,
    required this.matchCount,
  });

  final TextEditingController controller;
  final int itemCount;
  final int matchCount;

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
  void dispose() {
    widget.controller.dispose();
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
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: false,
        ignorePointers: !_hasFocus && widget.controller.text.isEmpty,
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
            child: _hasFocus || widget.controller.text.isNotEmpty
                ? Text(
                    t.search_match_count(widget.matchCount, widget.itemCount),
                  )
                : Text(t.password),
          ),
          prefixIcon: IconButton(
            onPressed: _showSearchHelp,
            icon: AnimatedOpacity(
              opacity: _hasFocus ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.help_outline_rounded),
            ),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              if (widget.controller.text.isNotEmpty) {
                widget.controller.clear();
              } else {
                _focusNode.unfocus();
              }
            },
            icon: AnimatedIconSwitcher(
              icon: !_hasFocus && widget.controller.text.isEmpty
                  ? const Icon(
                      Icons.search_rounded,
                      key: ValueKey(1),
                    )
                  : widget.controller.text.isNotEmpty
                      ? const Icon(
                          Icons.close,
                          key: ValueKey(2),
                        )
                      : const Icon(
                          Icons.arrow_downward_rounded,
                          key: ValueKey(3),
                        ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchHelp() {
    showDialog(
      context: context,
      builder: (context) {
        final t = I18n.of(context)!;

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(t.search_rule),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(t.rule_detail),
                ),
              ),
              ListTile(
                isThreeLine: true,
                title: Text(t.field_name),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('title(t) url'),
                      const SizedBox(height: 6),
                      const Text('user(u) email(e)'),
                      const SizedBox(height: 6),
                      const Text('note(n) password(p)'),
                      const SizedBox(height: 6),
                      const Text('OTPAuth(otp) tag'),
                      const SizedBox(height: 6),
                      const Text('group(g)'),
                      const SizedBox(height: 6),
                      Text(t.custom_field),
                    ],
                  ),
                ),
              ),
              ListTile(
                isThreeLine: true,
                title: Text(t.search_eg),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.search_eg_1),
                      const SizedBox(height: 6),
                      Text(t.search_eg_2),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(t.confirm),
            ),
          ],
        );
      },
    );
  }
}

class _OpenContainerPasswordItem extends StatelessWidget {
  const _OpenContainerPasswordItem({
    required this.kdbxEntry,
  });

  final KdbxEntry kdbxEntry;

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
      routeSettings: RouteSettings(arguments: kdbxEntry),
      openBuilder: (BuildContext context, VoidCallback _) {
        if (isLogPress) {
          return const EditAccountPage();
        }
        return const LookAccountPage();
      },
      closedElevation: 2,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return _PasswordItem(
          kdbxEntry: kdbxEntry,
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
    required this.kdbxEntry,
    this.onTop,
    this.onLongPress,
  });

  final KdbxEntry kdbxEntry;
  final GestureTapCallback? onTop;
  final GestureLongPressCallback? onLongPress;

  @override
  State<_PasswordItem> createState() => _PasswordItemState();
}

class _PasswordItemState extends State<_PasswordItem> {
  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final kdbxEntry = widget.kdbxEntry;
    return ListTile(
      isThreeLine: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: KdbxIconWidget(
          kdbxIcon: KdbxIconWidgetData(
            icon: kdbxEntry.icon.get() ?? KdbxIcon.Key,
            customIcon: kdbxEntry.customIcon,
          ),
          size: 24,
        ),
      ),
      title: Text(
        kdbxEntry.isExpiry()
            ? "${kdbxEntry.getNonNullString(KdbxKeyCommon.TITLE)} (${t.expires})"
            : kdbxEntry.getNonNullString(KdbxKeyCommon.TITLE),
        style: kdbxEntry.isExpiry()
            ? Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Theme.of(context).colorScheme.error)
            : Theme.of(context).textTheme.titleLarge,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              kdbxEntry.getNonNullString(KdbxKeyCommon.URL),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          _subtitleText(
            t.account_ab,
            kdbxEntry.getNonNullString(KdbxKeyCommon.USER_NAME),
          ),
          _subtitleText(
            t.email_ab,
            kdbxEntry.getNonNullString(KdbxKeyCommon.EMAIL),
          ),
          _subtitleText(
            t.label_ab,
            kdbxEntry.tagList.join(", "),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              kdbxEntry.parent?.name.get() ?? '',
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
        style: Theme.of(context).textTheme.titleMedium,
        text: "$subLabel ",
        children: [
          TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            text: text,
          )
        ],
      ),
    );
  }
}
