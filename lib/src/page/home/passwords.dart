import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../component/highlight_text.dart';
import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/common.dart';
import '../page.dart';

class PasswordsPage extends StatefulWidget {
  const PasswordsPage({super.key});

  @override
  State<PasswordsPage> createState() => PasswordsPageState();
}

class PasswordsPageState extends State<PasswordsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<KdbxEntry> _totalEntry = [];
  String _searchText = "";

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      KdbxProvider.of(context)!.addListener(_searchAccounts);
    });
    _searchAccounts();
    super.initState();
  }

  @override
  void dispose() {
    KdbxProvider.of(context)!.removeListener(_searchAccounts);
    super.dispose();
  }

  void _searchAccounts() {
    _totalEntry.clear();
    final kdbx = KdbxProvider.of(context)!;
    if (_searchText.isNotEmpty) {
      final searchText = _searchText.toLowerCase();
      _totalEntry.addAll(kdbx.totalEntry.where((item) {
        var weight = 0;
        for (var key in KdbxKeyCommon.all) {
          weight += (item.getString(key)?.getText() ?? '')
                  .toLowerCase()
                  .contains(searchText)
              ? 1
              : 0;
        }
        weight += item.tagList.contains(searchText) ? 1 : 0;

        return weight > 0;
      }));
    } else {
      _totalEntry.addAll(kdbx.totalEntry);
    }

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
          itemCount: kdbx.totalEntry.length,
          matchCount: _searchText.isNotEmpty ? _totalEntry.length : 0,
          onChanged: (text) {
            _searchText = text;
            _searchAccounts();
          },
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
          return _OpenContainerPasswordItem(
            kdbxEntry: _totalEntry[index],
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
              if (_controller.text.isNotEmpty) {
                _controller.clear();
              } else {
                _focusNode.unfocus();
              }
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
    required this.kdbxEntry,
    this.matchText,
  });

  final KdbxEntry kdbxEntry;
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
    required this.kdbxEntry,
    this.matchText,
    this.onTop,
    this.onLongPress,
  });

  final KdbxEntry kdbxEntry;
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
      title: HighlightText(
        text: kdbxEntry.getNonNullString(KdbxKeyCommon.TITLE),
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
              text: kdbxEntry.getNonNullString(KdbxKeyCommon.URL),
              matchText: widget.matchText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          _subtitleText(t.account_ab,
              kdbxEntry.getNonNullString(KdbxKeyCommon.USER_NAME)),
          _subtitleText(
              t.email_ab, kdbxEntry.getNonNullString(KdbxKeyCommon.EMAIL)),
          _subtitleText(t.label_ab, kdbxEntry.tagList.join(", ")),
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
