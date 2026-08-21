import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// kdbx 的 `Icon` 与 Flutter 的 `Icon` 重名，所以整个库都加前缀导入。
import 'package:keepass_core/keepass_core.dart' as kdbx;

Widget buildKdbxExample(BuildContext context) => const KdbxExamplePage();

/// kdbx 示例：新建 / 打开数据库，浏览分组与条目，增删改条目并保存。
class KdbxExamplePage extends StatefulWidget {
  const KdbxExamplePage({super.key});

  @override
  State<KdbxExamplePage> createState() => _KdbxExamplePageState();
}

class _KdbxExamplePageState extends State<KdbxExamplePage> {
  final _pathController = TextEditingController(
    text: '${Directory.systemTemp.path}/kdbxdb_example.kdbx',
  );
  final _passwordController = TextEditingController(text: 'demo-password');
  final _searchController = TextEditingController();

  kdbx.Kdbx? _db;
  kdbx.Meta? _meta;
  List<kdbx.GroupData> _groups = const [];
  List<kdbx.EntryData> _entries = const [];
  String? _selectedGroupId;
  int _totalEntryCount = 0;
  bool _busy = false;

  String? get _rootGroupId =>
      _groups.where((group) => group.parent == null).firstOrNull?.id;

  String? get _recycleBinId => _meta?.recyclebinUuid;

  @override
  void dispose() {
    _pathController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(String label, Future<void> Function() body) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await body();
      if (mounted) _showMessage('$label 完成');
    } catch (error) {
      if (mounted) _showMessage('$label 失败：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  kdbx.Credentials get _credentials =>
      kdbx.Credentials.from(password: _passwordController.text);

  Future<void> _createDatabase() => _run('新建数据库', () async {
    final db = kdbx.Kdbx.create(
      credentials: _credentials,
      filepath: _pathController.text.trim(),
    );
    await db.saveFile();
    _db = db;
    _selectedGroupId = null;
    await _reload();
  });

  Future<void> _openDatabase() => _run('打开数据库', () async {
    final db = await kdbx.Kdbx.open(
      credentials: _credentials,
      filepath: _pathController.text.trim(),
    );
    _db = db;
    _selectedGroupId = null;
    await _reload();
  });

  Future<void> _saveDatabase() => _run('保存', () async {
    await _db?.saveFile();
  });

  void _closeDatabase() {
    setState(() {
      _db = null;
      _meta = null;
      _groups = const [];
      _entries = const [];
      _selectedGroupId = null;
      _totalEntryCount = 0;
    });
  }

  /// 重新拉取 meta、分组和当前筛选条件下的条目。
  ///
  /// `includeRecycle` 的实际语义是「跳过回收站」，所以浏览回收站本身时反而要传 false，
  /// 同时用 `ignoreGroupConfig` 绕过回收站上关掉的 display 开关。
  Future<void> _reload() async {
    final db = _db;
    if (db == null) return;

    final search = _searchController.text.trim();
    final viewingAll = _selectedGroupId == null;

    final (summary, meta, groups) = await db.summary();

    final entries = await db.getEntrys(
      sreach: search.isEmpty ? null : search,
      groupId: _selectedGroupId,
      ignoreGroupConfig: !viewingAll,
      includeRecycle: viewingAll,
    );

    entries.sort(
      (a, b) => _title(a).toLowerCase().compareTo(_title(b).toLowerCase()),
    );

    if (!mounted) return;
    setState(() {
      _meta = meta;
      _groups = groups.values.toList();
      _entries = entries;
      _totalEntryCount = summary.totalEntryCount;
    });
  }

  Future<void> _addEntry() async {
    final parent = _selectedGroupId ?? _rootGroupId;
    if (parent == null) return;

    final draft = await _editEntryDialog();
    if (draft == null) return;

    await _run('新增条目', () async {
      await _db!.action(
        action: kdbx.KdbxAction.updateEntry(
          kdbx.EntryData.raw(
            id: _newUuid(),
            parent: parent,
            fields: _fieldsOf(draft),
            tags: const [],
            times: kdbx.Times(),
            customData: const {},
            qualityCheck: true,
            attachments: const [],
          ),
        ),
      );
      await _reload();
    });
  }

  Future<void> _updateEntry(kdbx.EntryData entry) async {
    final draft = await _editEntryDialog(entry: entry);
    if (draft == null) return;

    await _run('更新条目', () async {
      entry.fields
        ..clear()
        ..addAll(_fieldsOf(draft));
      await _db!.action(action: kdbx.KdbxAction.updateEntry(entry));
      await _reload();
    });
  }

  Future<void> _addGroup() async {
    final parent = _selectedGroupId ?? _rootGroupId;
    if (parent == null) return;

    final name = await _textInputDialog(title: '新建分组', label: '分组名称');
    if (name == null || name.isEmpty) return;

    await _run('新建分组', () async {
      await _db!.action(
        action: kdbx.KdbxAction.updateGroup(
          kdbx.GroupData.raw(
            id: _newUuid(),
            parent: parent,
            name: name,
            tags: const [],
            times: kdbx.Times(),
            customData: const {},
            isExpanded: true,
            isRecycleBin: false,
          ),
        ),
      );
      await _reload();
    });
  }

  Future<void> _renameDatabase() async {
    final name = await _textInputDialog(
      title: '重命名数据库',
      label: '数据库名称',
      initialValue: _meta?.databaseName ?? '',
    );
    if (name == null) return;

    await _run('重命名数据库', () async {
      final updateMeta = await _db!.getUpdateMeta();
      updateMeta.databaseName = name;

      await _db!.action(action: kdbx.KdbxAction.updateMeta(updateMeta));
      await _reload();
    });
  }

  Future<void> _entryAction(String label, kdbx.KdbxAction action) =>
      _run(label, () async {
        await _db!.action(action: action);
        await _reload();
      });

  Map<String, kdbx.FieldValue> _fieldsOf(_EntryDraft draft) {
    return {
      kdbx.KdbxKey.KEY_TITLE: kdbx.FieldValue(value: draft.title),
      kdbx.KdbxKey.KEY_USER_NAME: kdbx.FieldValue(value: draft.username),
      kdbx.KdbxKey.KEY_PASSWORD: kdbx.FieldValue(
        value: draft.password,
        protected: true,
      ),
      kdbx.KdbxKey.KEY_URL: kdbx.FieldValue(value: draft.url),
      kdbx.KdbxKey.KEY_NOTES: kdbx.FieldValue(value: draft.notes),
    };
  }

  String _field(kdbx.EntryData entry, String key) {
    try {
      return entry.fields[key]?.get() ?? '';
    } catch (_) {
      return '<解码失败>';
    }
  }

  String _title(kdbx.EntryData entry) {
    final title = _field(entry, kdbx.KdbxKey.KEY_TITLE);
    return title.isEmpty ? '(未命名)' : title;
  }

  @override
  Widget build(BuildContext context) {
    final db = _db;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kdbx'),
        actions: [
          if (db != null) ...[
            IconButton(
              onPressed: _busy ? null : _saveDatabase,
              icon: const Icon(Icons.save_outlined),
              tooltip: '保存',
            ),
            IconButton(
              onPressed: _busy ? null : _closeDatabase,
              icon: const Icon(Icons.logout),
              tooltip: '关闭',
            ),
          ],
        ],
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton: db == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _busy ? null : _addEntry,
              icon: const Icon(Icons.add),
              label: const Text('新增条目'),
            ),
      body: db == null ? _connectView() : _databaseView(),
    );
  }

  Widget _connectView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('数据库', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: _pathController,
                  decoration: const InputDecoration(
                    labelText: '文件路径',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '主密码',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : _createDatabase,
                      icon: const Icon(Icons.note_add_outlined),
                      label: const Text('新建'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : _openDatabase,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('打开'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '新建会立即写入上面的路径，同名文件会被覆盖。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _databaseView() {
    return Column(
      children: [
        _metaCard(),
        _filterBar(),
        const Divider(height: 1),
        Expanded(
          child: _entries.isEmpty
              ? const Center(child: Text('没有条目'))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: _entries.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) => _entryTile(_entries[index]),
                ),
        ),
      ],
    );
  }

  Widget _metaCard() {
    final meta = _meta;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meta?.databaseName?.isNotEmpty == true
                        ? meta!.databaseName!
                        : '(未命名数据库)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : _renameDatabase,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '重命名',
                ),
                IconButton(
                  onPressed: _busy ? null : _addGroup,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  tooltip: '新建分组',
                ),
              ],
            ),
            Text(
              '生成器 ${meta?.generator ?? '-'} · $_totalEntryCount 个条目（不含回收站） · '
              '${_groups.length} 个分组',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _pathController.text,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: (value) => _reload(),
            decoration: InputDecoration(
              hintText: '搜索条目',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                onPressed: () {
                  _searchController.clear();
                  _reload();
                },
                icon: const Icon(Icons.clear),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('全部'),
                  selected: _selectedGroupId == null,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() => _selectedGroupId = null);
                    _reload();
                  },
                ),
                for (final group in _groups)
                  if (group.parent != null)
                    ChoiceChip(
                      label: Text(
                        group.id == _recycleBinId ? '回收站' : group.name,
                      ),
                      selected: _selectedGroupId == group.id,
                      onSelected: (selected) {
                        if (!selected) return;
                        setState(() => _selectedGroupId = group.id);
                        _reload();
                      },
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _entryTile(kdbx.EntryData entry) {
    final username = _field(entry, kdbx.KdbxKey.KEY_USER_NAME);
    final url = _field(entry, kdbx.KdbxKey.KEY_URL);
    final subtitle = [
      username,
      url,
    ].where((value) => value.isNotEmpty).join(' · ');
    final inRecycleBin = entry.parent == _recycleBinId;

    return ListTile(
      leading: CircleAvatar(child: Text(_title(entry).characters.first)),
      title: Text(_title(entry)),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      onTap: _busy ? null : () => _updateEntry(entry),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => switch (value) {
          'copy' => _copyPassword(entry),
          'trash' => _entryAction(
            '移入回收站',
            kdbx.KdbxAction.move2Trash([entry.id]),
          ),
          'restore' => _entryAction('还原', kdbx.KdbxAction.restore([entry.id])),
          _ => _entryAction('删除', kdbx.KdbxAction.delete([entry.id])),
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'copy', child: Text('复制密码')),
          if (inRecycleBin)
            const PopupMenuItem(value: 'restore', child: Text('还原'))
          else
            const PopupMenuItem(value: 'trash', child: Text('移入回收站')),
          const PopupMenuItem(value: 'delete', child: Text('彻底删除')),
        ],
      ),
    );
  }

  Future<void> _copyPassword(kdbx.EntryData entry) async {
    await Clipboard.setData(
      ClipboardData(text: _field(entry, kdbx.KdbxKey.KEY_PASSWORD)),
    );
    _showMessage('密码已复制到剪贴板');
  }

  Future<_EntryDraft?> _editEntryDialog({kdbx.EntryData? entry}) {
    return showDialog<_EntryDraft>(
      context: context,
      builder: (context) => _EntryEditorDialog(
        initial: entry == null
            ? const _EntryDraft()
            : _EntryDraft(
                title: _field(entry, kdbx.KdbxKey.KEY_TITLE),
                username: _field(entry, kdbx.KdbxKey.KEY_USER_NAME),
                password: _field(entry, kdbx.KdbxKey.KEY_PASSWORD),
                url: _field(entry, kdbx.KdbxKey.KEY_URL),
                notes: _field(entry, kdbx.KdbxKey.KEY_NOTES),
              ),
      ),
    );
  }

  Future<String?> _textInputDialog({
    required String title,
    required String label,
    String initialValue = '',
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}

class _EntryDraft {
  const _EntryDraft({
    this.title = '',
    this.username = '',
    this.password = '',
    this.url = '',
    this.notes = '',
  });

  final String title;
  final String username;
  final String password;
  final String url;
  final String notes;
}

class _EntryEditorDialog extends StatefulWidget {
  const _EntryEditorDialog({required this.initial});

  final _EntryDraft initial;

  @override
  State<_EntryEditorDialog> createState() => _EntryEditorDialogState();
}

class _EntryEditorDialogState extends State<_EntryEditorDialog> {
  late final _titleController = TextEditingController(
    text: widget.initial.title,
  );
  late final _usernameController = TextEditingController(
    text: widget.initial.username,
  );
  late final _passwordController = TextEditingController(
    text: widget.initial.password,
  );
  late final _urlController = TextEditingController(text: widget.initial.url);
  late final _notesController = TextEditingController(
    text: widget.initial.notes,
  );

  bool _obscurePassword = true;

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('条目'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_titleController, '标题', autofocus: true),
              _field(_usernameController, '用户名'),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '密码',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _field(_urlController, '网址'),
              _field(_notesController, '备注', maxLines: 3),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _EntryDraft(
              title: _titleController.text,
              username: _usernameController.text,
              password: _passwordController.text,
              url: _urlController.text,
              notes: _notesController.text,
            ),
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool autofocus = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// kdbx 用 UUID 作为条目和分组的主键，新建时需要自己生成一个 v4。
String _newUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int start, int end) => bytes
      .sublist(start, end)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
