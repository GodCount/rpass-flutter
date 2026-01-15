import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../remotes_fs/remote_fs.dart';
import '../../util/common.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
import '../auth_kdbx/load_ext_page.dart';

class _ImportRemoteKdbxArgs extends PageRouteArgs {
  _ImportRemoteKdbxArgs({
    super.key,
    required this.client,
  });

  final RemoteClient client;
}

class ImportRemoteKdbxRoute extends PageRouteInfo<_ImportRemoteKdbxArgs> {
  ImportRemoteKdbxRoute({
    Key? key,
    bool save = false,
    required RemoteClient client,
  }) : super(
          name,
          args: _ImportRemoteKdbxArgs(
            key: key,
            client: client,
          ),
        );

  static const name = "ImportRemoteKdbxRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_ImportRemoteKdbxArgs>();
      return ImportRemoteKdbxPage(
        key: args.key,
        client: args.client,
      );
    },
  );
}

class ImportRemoteKdbxPage extends StatefulWidget {
  const ImportRemoteKdbxPage({
    super.key,
    required this.client,
  });

  final RemoteClient client;

  @override
  State<ImportRemoteKdbxPage> createState() => _ImportRemoteKdbxState();
}

class _ImportRemoteKdbxState extends State<ImportRemoteKdbxPage> {
  bool _loading = true;

  RemoteFile? _selectedFile;

  RemoteFileNode _currentFileNode = RemoteFileNode();

  @override
  void initState() {
    super.initState();
    _readdir();
  }

  Future<void> _readdir([RemoteFileNode? node]) async {
    try {
      setState(() {
        _loading = true;
        _selectedFile = null;
      });

      if (_currentFileNode.file == null && node == null) {
        // 根目录

        final info = await widget.client.readFileInfo("");

        if (info.dir) {
          _currentFileNode.children = (await widget.client.readdir(""))
              .map((item) => RemoteFileNode(
                    file: item,
                    parent: _currentFileNode,
                  ))
              .toList();
        } else {
          _currentFileNode.children = [RemoteFileNode(file: info)];
        }
      } else if (node == null) {
        // 刷新
        _currentFileNode.children = (await _currentFileNode.file!.readdir())
            .map((item) => RemoteFileNode(
                  file: item,
                  parent: _currentFileNode,
                ))
            .toList();
      } else {
        // 返回到根目录
        if (node.file == null) {
          node.children ??= (await widget.client.readdir(""))
              .map((item) => RemoteFileNode(
                    file: item,
                    parent: node,
                  ))
              .toList();
        } else {
          // 进入子文件夹
          node.children ??= (await node.file!.readdir())
              .map((item) => RemoteFileNode(
                    file: item,
                    parent: node,
                  ))
              .toList();
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

  void _openKdbxFile() async {
    if (_selectedFile == null) return;
    try {
      if (_selectedFile!.size == 0) {
        throw Exception("Current file is empty, path a ${_selectedFile!.path}");
      }

      final result = await context.router.push(LoadExternalKdbxRoute(
        kdbxFile: await _selectedFile!.readFile(),
      ));

      if (result != null && result is (Kdbx, String?)) {
        context.router.pop(result);
      }
    } catch (e) {
      showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    List<Widget> children;

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
            )
          ],
        ),
      ).repeat(3);
    } else {
      children = [
        if (_currentFileNode.parent != null)
          _buildFileListTile(_currentFileNode.parent!),
        if (_currentFileNode.children != null)
          ..._currentFileNode.children!.map(_buildFileListTile)
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.import_remote_kdbx),
        actions: [
          IconButton(
            onPressed: !_loading ? () => _readdir() : null,
            icon: const Icon(Icons.replay_outlined),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: children.length,
        itemBuilder: (context, i) {
          return children[i];
        },
      ),
      floatingActionButton: _selectedFile != null
          ? FloatingActionButton(
              heroTag: const ValueKey("import_remote_float"),
              onPressed: _openKdbxFile,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(56 / 2),
                ),
              ),
              child: const Icon(Icons.done),
            )
          : null,
    );
  }

  Widget _buildFileListTile(RemoteFileNode node) {
    final isPrev = node == _currentFileNode.parent;
    final file = node.file;

    return ListTile(
      enabled: file == null || file.dir || file.name.endsWith(".kdbx"),
      onTap: () {
        if (file == null || file.dir) {
          _readdir(node);
        } else {
          setState(() {
            _selectedFile = _selectedFile == file ? null : file;
          });
        }
      },
      title: Text(isPrev || file == null ? ".." : file.name),
      subtitle: Row(
        spacing: 6,
        children: !isPrev && file != null
            ? [
                if (file.mTime != null || file.cTime != null)
                  Text((file.mTime ?? file.cTime)!.formatDate),
                if (!file.dir) Text(file.size.bytesToBestUnit)
              ]
            : [const Text("")],
      ),
      leading: Icon(file == null || file.dir ? Icons.folder : Icons.file_open),
      trailing:
          file != null && file == _selectedFile ? const Icon(Icons.done) : null,
    );
  }
}

class RemoteFileNode {
  RemoteFileNode({
    this.file,
    this.parent,
    this.children,
  });

  final RemoteFile? file;
  final RemoteFileNode? parent;
  List<RemoteFileNode>? children;
}
