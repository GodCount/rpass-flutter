import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/index.dart';

import '../../rpass.dart';
import '../../util/route.dart';
import '../../i18n.dart';

class _SelectAutoFillAppArgs extends PageRouteArgs {
  _SelectAutoFillAppArgs({
    super.key,
  });
}

class SelectAutoFillAppRoute extends PageRouteInfo<_SelectAutoFillAppArgs> {
  SelectAutoFillAppRoute({
    Key? key,
    String? packageName,
  }) : super(
          name,
          args: _SelectAutoFillAppArgs(
            key: key,
          ),
        );

  static const name = "SelectAutoFillAppRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_SelectAutoFillAppArgs>(
        orElse: () => _SelectAutoFillAppArgs(),
      );
      return SelectAutoFillAppPage(
        key: args.key,
      );
    },
  );
}

class SelectAutoFillAppPage extends StatefulWidget {
  const SelectAutoFillAppPage({
    super.key,
  });

  @override
  State<SelectAutoFillAppPage> createState() => _SelectAutoFillAppPageState();
}

class _SelectAutoFillAppPageState extends State<SelectAutoFillAppPage> {
  final TextEditingController _searchController = TextEditingController();

  Future<List<AppInfo>>? _future;
  bool _system = false;

  @override
  void initState() {
    super.initState();
    String lastText = "";
    _searchController.addListener(
      () {
        if (lastText != _searchController.text) {
          lastText = _searchController.text;
          setState(() {
            _future = _sreach();
          });
        }
      },
    );

    setState(() {
      _future = _sreach();
    });
  }

  Future<List<AppInfo>> _sreach({
    bool force = false,
    bool? system,
  }) async {
    _system = system ?? _system;

    final text = _searchController.text.toLowerCase();

    final result = (await InstalledAppsInstance.instance
            .getInstalledApps(force))
        .where((it) {
      if (it.packageName == RpassInfo.packageName) return false;

      if (!_system && it.isSystem) return false;

      return text.isNotEmpty ? it.name.toLowerCase().contains(text) : true;
    }).toList()
      ..sort((a, b) => b.installedTimestamp - a.installedTimestamp);

    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: TextField(
            controller: _searchController,
            cursorHeight: 16,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isCollapsed: true,
              contentPadding: const EdgeInsets.all(12),
              hintText: t.search,
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
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              switch (value) {
                case "refresh":
                  setState(() {
                    _future = _sreach(force: true);
                  });
                  break;
                case "system":
                  setState(() {
                    _future = _sreach(system: !_system);
                  });
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: "refresh",
                  child: Text(t.refresh),
                ),
                PopupMenuItem(
                  value: "system",
                  child: Text(
                    _system ? t.hide_system_apps : t.show_system_apps,
                  ),
                ),
              ];
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: snapshot.hasError
                  ? Text("${snapshot.error}")
                  : const CircularProgressIndicator(),
            );
          }

          final data = snapshot.data ?? [];

          return ListView.builder(
            itemCount: data.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  onTap: () {
                    context.router.pop("none");
                  },
                  leading: const Icon(Icons.android),
                  title: Text(t.none),
                  subtitle: Text(t.auto_fill_apps_none_subtitle),
                );
              }
              final item = data[index - 1];
              return ListTile(
                onTap: () {
                  context.router.pop(item.packageName);
                },
                leading: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Image.memory(item.icon),
                  ),
                ),
                title: Text(item.name),
                subtitle: Text(item.packageName),
              );
            },
          );
        },
      ),
    );
  }
}
