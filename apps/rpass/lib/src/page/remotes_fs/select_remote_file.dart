import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:remote_fs/remote_fs.dart';

import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../util/common.dart';
import '../../util/route.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';
import '../auth_kdbx/load_ext_page.dart';

class _SelectRemoteFileArgs extends PageRouteArgs {
  _SelectRemoteFileArgs({
    super.key,
    required this.config,
    this.importKdbx = false,
  });

  final RemoteFileConfig config;

  final bool importKdbx;
}

class SelectRemoteFileRoute extends PageRouteInfo<_SelectRemoteFileArgs> {
  SelectRemoteFileRoute({
    Key? key,
    required RemoteFileConfig config,
    bool importKdbx = false,
  }) : super(
         name,
         args: _SelectRemoteFileArgs(
           key: key,
           config: config,
           importKdbx: importKdbx,
         ),
       );

  static const name = "SelectRemoteFileRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_SelectRemoteFileArgs>();
      return SelectRemoteFilePage(
        key: args.key,
        config: args.config,
        importKdbx: args.importKdbx,
      );
    },
  );
}

class SelectRemoteFilePage extends StatefulWidget {
  const SelectRemoteFilePage({
    super.key,
    required this.config,
    this.importKdbx = false,
  });

  final RemoteFileConfig config;
  final bool importKdbx;

  @override
  State<SelectRemoteFilePage> createState() => _SelectRemoteFileState();
}

class _SelectRemoteFileState extends State<SelectRemoteFilePage> {
  bool _loading = true;

  RemoteFileNode? _selectedNode;

  RemoteFileNode? _currentFileNode;

  @override
  void initState() {
    super.initState();
    _readdir();
  }

  Future<void> _readdir([RemoteFileNode? node]) async {
    try {
      setState(() {
        _loading = true;
        _selectedNode = null;
      });

      if (_currentFileNode == null) {
        RemoteFile remoteFile = await widget.config.open();
        final stat = await remoteFile.stat();
        if (stat.type == .file) {
          remoteFile = await remoteFile.relative("..");
        }

        _currentFileNode = RemoteFileNode(
          file: remoteFile,
          stat: await remoteFile.stat(),
          children: [],
        );

        for (final item in await remoteFile.list()) {
          _currentFileNode!.children!.add(
            RemoteFileNode(
              file: await remoteFile.relative(item.name),
              stat: item,
              parent: _currentFileNode,
            ),
          );
        }
      } else if (node == null) {
        _currentFileNode!.children = [];

        for (final item in await _currentFileNode!.file.list()) {
          _currentFileNode!.children!.add(
            RemoteFileNode(
              file: await _currentFileNode!.file.relative(item.name),
              stat: item,
              parent: _currentFileNode,
            ),
          );
        }
      } else if (node.stat.type == .directory) {
        if (node.children == null) {
          node.children = [];
          for (final item in await node.file.list()) {
            node.children!.add(
              RemoteFileNode(
                file: await node.file.relative(item.name),
                stat: item,
                parent: node,
              ),
            );
          }
        }
        _currentFileNode = node;
      }
    } catch (e) {
      showError(e);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _popResult() async {
    if (_selectedNode == null) return;
    try {
      if (widget.importKdbx) {
        final file = _selectedNode!.file;

        if (_selectedNode!.stat.type != .file) {
          throw Exception("Current file is empty, path a ${file.path}");
        }

        final result = await context.router.push(
          LoadExternalKdbxRoute(kdbxFile: await file.read()),
        );

        if (result != null && result is (Kdbx, String?)) {
          context.router.pop(result);
        }
      } else {
        context.router.pop(await _selectedNode!.file.toConfig());
      }
    } catch (e) {
      showError(e);
    }
  }

  void _showMenu() {
    final t = I18n.of(context)!;

    GestureTapCallback? onAutoPop(GestureTapCallback func) {
      return () async {
        context.router.pop();
        func.call();
      };
    }

    showBottomSheetList(
      title: t.menu,
      children: [
        ListTile(
          enabled: !_loading,
          title: Text(t.refresh),
          leading: const Icon(Icons.replay_outlined),
          onTap: onAutoPop(_readdir),
        ),
        ListTile(
          enabled: _currentFileNode != null,
          title: Text(t.create),
          leading: const Icon(Icons.create_new_folder),
          onTap: onAutoPop(() async {
            if (_currentFileNode != null) {
              final result = await InputDialog.openDialog(
                context,
                title: t.create,
              );
              if (result != null && result is String) {
                try {
                  final file = await _currentFileNode!.file.relative(result);
                  await file.mkdir();
                  _readdir();
                } catch (e) {
                  showError(e);
                }
              }
            }
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    List<Widget> children = [];

    if (_loading) {
      children = ListTile(
        leading: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            color: Colors.grey,
          ),
        ),
        title: Container(
          height: 18,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            color: Colors.grey,
          ),
        ),
        subtitle: Row(
          spacing: 6,
          children: [
            Container(
              width: 96,
              height: 12,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                color: Colors.grey,
              ),
            ),
            Container(
              width: 48,
              height: 12,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ).repeat(3);
    } else if (_currentFileNode != null) {
      children = [
        if (_currentFileNode!.parent != null)
          _buildFileListTile(_currentFileNode!.parent!),
        if (_currentFileNode!.children != null)
          ..._currentFileNode!.children!.map(_buildFileListTile),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.importKdbx ? t.import_remote_kdbx : t.save_as),
        actions: [
          IconButton(onPressed: _showMenu, icon: const Icon(Icons.menu)),
        ],
      ),
      body: ListView.builder(
        itemCount: children.length,
        itemBuilder: (context, i) {
          return children[i];
        },
      ),
      floatingActionButton: _selectedNode != null
          ? FloatingActionButton(
              heroTag: const ValueKey("select_remote_file_float"),
              onPressed: _popResult,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(56 / 2)),
              ),
              child: const Icon(Icons.done),
            )
          : null,
    );
  }

  Widget _buildFileListTile(RemoteFileNode node) {
    final isPrev = node == _currentFileNode!.parent;
    final stat = node.stat;

    return ListTile(
      enabled:
          stat.type == .directory ||
          (stat.type == .file && stat.name.endsWith(".kdbx")),
      onTap: () {
        if (stat.type == .directory) {
          _readdir(node);
        } else {
          setState(() {
            _selectedNode = _selectedNode == node ? null : node;
          });
        }
      },
      onLongPress: !widget.importKdbx
          ? () {
              if (!isPrev && stat.type == .directory) {
                setState(() {
                  _selectedNode = _selectedNode == node ? null : node;
                });
              }
            }
          : null,
      title: Text(isPrev ? ".." : stat.name),
      subtitle: Row(
        spacing: 6,
        children: !isPrev
            ? [
                Text(stat.modified.formatDate),
                if (stat.type == .file) Text(stat.size.bytesToBestUnit),
              ]
            : [Text("")],
      ),
      leading: Icon(stat.type == .directory ? Icons.folder : Icons.file_open),
      trailing: node == _selectedNode ? const Icon(Icons.done) : null,
    );
  }
}

class RemoteFileNode {
  RemoteFileNode({
    required this.file,
    required this.stat,
    this.parent,
    this.children,
  });

  final RemoteFile file;
  final RemoteFileStat stat;
  final RemoteFileNode? parent;
  List<RemoteFileNode>? children;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is RemoteFileNode && other.file.path == file.path;
  }

  @override
  int get hashCode => file.path.hashCode;
}
