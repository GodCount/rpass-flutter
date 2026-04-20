import 'package:auto_route/auto_route.dart';
import 'package:common_native_channel/common_native_channel.dart';
import 'package:flutter/material.dart';

import '../../rpass.dart';
import '../../util/route.dart';
import '../../i18n.dart';
import '../../widget/common.dart';

class _SelectAutoFillAppArgs extends PageRouteArgs {
  _SelectAutoFillAppArgs({super.key, this.packageNames, this.single});

  final List<String>? packageNames;
  final bool? single;
}

class SelectAutoFillAppRoute extends PageRouteInfo<_SelectAutoFillAppArgs> {
  SelectAutoFillAppRoute({Key? key, List<String>? packageNames, bool? single})
    : super(
        name,
        args: _SelectAutoFillAppArgs(
          key: key,
          packageNames: packageNames,
          single: single,
        ),
        rawQueryParams: {"packageNames": packageNames, "single": single},
      );

  static const name = "SelectAutoFillAppRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_SelectAutoFillAppArgs>(
        orElse: () {
          return _SelectAutoFillAppArgs(
            packageNames: data.queryParams.getList("packageNames", []),
            single: data.queryParams.getBool("single", false),
          );
        },
      );
      return SelectAutoFillAppPage(
        key: args.key,
        packageNames: args.packageNames,
        single: args.single ?? false,
      );
    },
  );
}

class SelectAutoFillAppPage extends StatefulWidget {
  SelectAutoFillAppPage({
    super.key,
    List<String>? packageNames,
    this.single = false,
  }) : packageNames = packageNames ?? [];

  final List<String> packageNames;
  final bool single;

  @override
  State<SelectAutoFillAppPage> createState() => _SelectAutoFillAppPageState();
}

class _SelectAutoFillAppPageState extends State<SelectAutoFillAppPage> {
  final TextEditingController _searchController = TextEditingController();

  Future<List<AppInfo>>? _future;
  bool _system = false;

  bool _dirty = false;
  bool _loading = false;

  late List<String> packageNames = widget.packageNames;

  @override
  void initState() {
    super.initState();
    String lastText = "";
    _searchController.addListener(() {
      if (lastText != _searchController.text) {
        lastText = _searchController.text;
        setState(() {
          _future = _sreach();
        });
      }
    });

    setState(() {
      _future = _sreach();
    });
  }

  Future<List<AppInfo>> _sreach({bool force = false, bool? system}) async {
    _system = system ?? _system;
    _loading = true;

    setState(() {});

    final text = _searchController.text.toLowerCase();

    final result =
        (await installedApps.getInstalledApps(force)).where((it) {
          if (it.packageName == RpassInfo.packageName) return false;

          if (!_system && it.isSystem) return false;

          return text.isNotEmpty ? it.name.toLowerCase().contains(text) : true;
        }).toList()..sort((a, b) {
          final ac = packageNames.contains(a.packageName);
          final bc = packageNames.contains(b.packageName);

          if (ac != bc) {
            return ac ? -1 : 1;
          }

          return b.installedTimestamp - a.installedTimestamp;
        });

    _loading = false;
    setState(() {});

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
                        icon: const Icon(Icons.close, size: 16),
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
                PopupMenuItem(value: "refresh", child: Text(t.refresh)),
                PopupMenuItem(
                  value: "system",
                  child: Text(
                    _system ? t.hide_system_apps : t.show_system_apps,
                  ),
                ),
              ];
            },
          ),
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
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return ListTile(
                onTap: () {
                  if (widget.single) {
                    if (packageNames.isEmpty ||
                        packageNames.first != item.packageName) {
                      packageNames = [item.packageName];
                    } else {
                      packageNames = [];
                    }
                  } else {
                    if (packageNames.contains(item.packageName)) {
                      packageNames.remove(item.packageName);
                    } else {
                      packageNames.add(item.packageName);
                    }
                  }
                  _dirty = true;
                  setState(() {});
                },
                leading: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: ImageFileString(
                      item.icon,
                      error: const Icon(Icons.android_outlined, size: 18),
                    ),
                  ),
                ),
                title: Text(item.name),
                subtitle: Text(item.packageName),
                trailing: packageNames.contains(item.packageName)
                    ? const Icon(Icons.check)
                    : null,
              );
            },
          );
        },
      ),
      floatingActionButton: !_loading && _dirty
          ? FloatingActionButton(
              heroTag: const ValueKey("select_app_float"),
              onPressed: () {
                context.router.pop(packageNames);
              },
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(56 / 2)),
              ),
              child: Icon(Icons.done),
            )
          : null,
    );
  }
}
