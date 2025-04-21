import 'package:animations/animations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/common.dart';
import '../../util/route.dart';
import '../../widget/common.dart';
import '../password/edit_account.dart';
import '../password/look_account.dart';
import 'route_wrap.dart';
import '../../widget/extension_state.dart';

class _PasswordsArgs extends PageRouteArgs {
  _PasswordsArgs({super.key, this.search});
  final String? search;
}

class PasswordsRoute extends PageRouteInfo<_PasswordsArgs> {
  PasswordsRoute({
    Key? key,
    String? search,
  }) : super(
          name,
          args: _PasswordsArgs(
            key: key,
            search: search,
          ),
          rawQueryParams: {
            "search": search,
          },
        );

  static const name = "PasswordsRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_PasswordsArgs>(
        orElse: () => _PasswordsArgs(
          search: data.queryParams.optString("search"),
        ),
      );
      return PasswordsPage(
        key: args.key,
        search: args.search,
      );
    },
  );
}

class PasswordsPage extends StatefulWidget {
  const PasswordsPage({super.key, this.search});

  final String? search;

  @override
  State<PasswordsPage> createState() => _PasswordsPageState();
}

class _PasswordsPageState extends State<PasswordsPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  final KbdxSearchHandler _kbdxSearchHandler = KbdxSearchHandler();
  final List<KdbxEntry> _totalEntry = [];

  VoidCallback? _removeKdbxListener;

  @override
  void didUpdateWidget(covariant PasswordsPage oldWidget) {
    if (widget.search != null && oldWidget.search != widget.search) {
      _searchController.text = widget.search!;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    final kdbx = KdbxProvider.of(context)!;
    _searchController.addListener(_searchAccounts);
    _searchAccounts();

    kdbx.addListener(_onKdbxSave);
    _removeKdbxListener = () => kdbx.removeListener(_onKdbxSave);

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeKdbxListener?.call();
    _removeKdbxListener = null;
    _totalEntry.clear();
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
    return isDesktop ? RouteWrap(child: _buildDesktop()) : _buildMobile();
  }

  Widget _buildMobile() {
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

  Widget _buildDesktop() {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 6,
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TextField(
            controller: _searchController,
            cursorHeight: 16,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 12,
              ),
              hintText: t.search,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: IconButton(
                  iconSize: 16,
                  padding: const EdgeInsets.all(4),
                  onPressed: showSearchHelpDialog,
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 30,
                maxWidth: 30,
                minHeight: 24,
                maxHeight: 24,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _searchController.text.isNotEmpty
                    ? IconButton(
                        iconSize: 16,
                        padding: const EdgeInsets.all(4),
                        onPressed: () {
                          _searchController.text = "";
                        },
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                        ),
                      )
                    : null,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 30,
                maxWidth: 30,
                minHeight: 24,
                maxHeight: 24,
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 6),
        actions: [
          IconButton(
            onPressed: () {
              context.router.platformNavigate(EditAccountRoute());
            },
            icon: const Icon(Icons.add),
          ),
        ],
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
          return _PasswordItem(
            kdbxEntry: _totalEntry[index],
            onTap: () {
              context.router.platformNavigate(
                LookAccountRoute(
                  kdbxEntry: _totalEntry[index],
                  uuid: _totalEntry[index].uuid,
                ),
              );
            },
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
            onPressed: showSearchHelpDialog,
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
      openBuilder: (BuildContext context, VoidCallback _) {
        return isLogPress
            ? EditAccountPage(
                kdbxEntry: kdbxEntry,
              )
            : LookAccountPage(
                kdbxEntry: kdbxEntry,
              );
      },
      closedElevation: 2,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return _PasswordItem(
          kdbxEntry: kdbxEntry,
          onTap: () {
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
    this.onTap,
    this.onLongPress,
  });

  final KdbxEntry kdbxEntry;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;

  @override
  State<_PasswordItem> createState() => _PasswordItemState();
}

class _PasswordItemState extends State<_PasswordItem>
    with NavigationHistoryObserver<_PasswordItem> {
  bool _selected = false;
  bool _showMenu = false;

  @override
  void didNavigationHistory() {
    if (context.topRoute.name == LookAccountRoute.name ||
        context.topRoute.name == EditAccountRoute.name) {
      final selected = context.topRoute.inheritedPathParams.optString("uuid") ==
          widget.kdbxEntry.uuid.deBase64Uuid;

      if (selected != _selected) {
        setState(() {
          _selected = selected;
        });
      }
    } else if (_selected) {
      setState(() {
        _selected = false;
      });
    }
  }

  void _deletePassword() async {
    final t = I18n.of(context)!;
    if (await showConfirmDialog(
      title: t.delete,
      message: t.is_move_recycle,
    )) {
      final kdbx = KdbxProvider.of(context)!;
      kdbx.deleteEntry(widget.kdbxEntry);
      await kdbxSave(kdbx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final kdbxEntry = widget.kdbxEntry;
    return CustomContextMenuRegion<PasswordsItemMenu>(
      enabled: isDesktop,
      onItemSelected: (type) {
        setState(() {
          _showMenu = false;
        });
        if (type == null) {
          return;
        }
        switch (type) {
          case PasswordsItemMenu.edit:
            context.router.platformNavigate(
              EditAccountRoute(
                kdbxEntry: kdbxEntry,
                uuid: kdbxEntry.uuid,
              ),
            );
            break;
          case PasswordsItemMenu.copy:
            writeClipboard(kdbxEntry.getNonNullString(KdbxKeyCommon.USER_NAME));
            break;
          case PasswordsItemMenu.delete:
            _deletePassword();
            break;
        }
      },
      builder: (context) {
        setState(() {
          _showMenu = true;
        });

        return ContextMenu(
          entries: [
            MenuItem(
              label: t.edit_account,
              icon: Icons.edit,
              enabled:
                  context.topRoute.name != EditAccountRoute.name || !_selected,
              value: PasswordsItemMenu.edit,
            ),
            MenuItem(
              label: t.copy,
              icon: Icons.copy,
              value: PasswordsItemMenu.copy,
            ),
            const MenuDivider(),
            MenuItem(
              label: t.delete,
              icon: Icons.delete,
              value: PasswordsItemMenu.delete,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        );
      },
      child: ListTile(
        isThreeLine: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        selected: _selected || _showMenu,
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
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
      ),
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
