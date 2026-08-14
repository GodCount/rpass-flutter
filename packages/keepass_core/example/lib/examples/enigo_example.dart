import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keepass_core/keepass_core.dart' as enigo;

Widget buildEnigoExample(BuildContext context) => const EnigoExamplePage();

/// Enigo 示例：模拟键盘、鼠标输入，并展示 `PhysicalKeyboardKey` 与 Rust `Key` 的互转。
class EnigoExamplePage extends StatefulWidget {
  const EnigoExamplePage({super.key});

  @override
  State<EnigoExamplePage> createState() => _EnigoExamplePageState();
}

class _EnigoExamplePageState extends State<EnigoExamplePage> {
  static const _mouseButtons = <String>[
    'left',
    'middle',
    'right',
    'back',
    'forward',
  ];

  final _textController = TextEditingController(text: 'hello from enigo');
  final _xController = TextEditingController(text: '200');
  final _yController = TextEditingController(text: '200');
  final _scrollLengthController = TextEditingController(text: '3');
  final _keyCaptureFocusNode = FocusNode(debugLabel: 'enigo key capture');

  enigo.Enigo? _instance;
  bool _hasPermission = false;
  PhysicalKeyboardKey? _capturedKey;
  enigo.Coordinate _coordinate = enigo.Coordinate.abs;
  enigo.Axis _axis = enigo.Axis.vertical;
  String _mouseButton = 'left';
  int _delaySeconds = 3;
  int _countdown = 0;
  (int, int)? _display;
  (int, int)? _location;

  bool get _busy => _countdown > 0;

  @override
  void initState() {
    super.initState();
    _hasPermission = enigo.Enigo.hasPermission(openPrompt: false);
  }

  @override
  void dispose() {
    _textController.dispose();
    _xController.dispose();
    _yController.dispose();
    _scrollLengthController.dispose();
    _keyCaptureFocusNode.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Enigo 在 macOS 上没有辅助功能权限时会直接创建失败，所以延迟到第一次真正要用时再建。
  enigo.Enigo? _ensureInstance() {
    final existing = _instance;
    if (existing != null) return existing;
    try {
      return _instance = enigo.Enigo.preset();
    } catch (error) {
      _showMessage('创建 Enigo 失败：$error');
      return null;
    }
  }

  void _requestPermission() {
    final granted = enigo.Enigo.hasPermission(openPrompt: true);
    setState(() => _hasPermission = granted);
    _showMessage(granted ? '已获得权限' : '仍未获得权限，请在系统设置里授权后重试');
  }

  /// 倒计时结束后再执行，好让使用者有时间把焦点切到别的窗口，否则输入会打回示例自己身上。
  Future<void> _dispatch(
    String label,
    void Function(enigo.Enigo) action,
  ) async {
    final instance = _ensureInstance();
    if (instance == null) return;

    for (var remaining = _delaySeconds; remaining > 0; remaining--) {
      if (!mounted) return;
      setState(() => _countdown = remaining);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() => _countdown = 0);

    try {
      action(instance);
      _showMessage('$label 已发送');
    } catch (error) {
      _showMessage('$label 失败：$error');
    }
  }

  void _readMouseState() {
    final instance = _ensureInstance();
    if (instance == null) return;
    try {
      final display = instance.mainDisplay();
      final location = instance.location();
      setState(() {
        _display = display;
        _location = location;
      });
    } catch (error) {
      _showMessage('读取鼠标状态失败：$error');
    }
  }

  int _intFieldValue(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enigo'),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _permissionCard(),
          const SizedBox(height: 12),
          _delayCard(),
          const SizedBox(height: 12),
          _keyboardCard(),
          const SizedBox(height: 12),
          _mouseCard(),
        ],
      ),
    );
  }

  Widget _permissionCard() {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(
          _hasPermission ? Icons.verified_user : Icons.gpp_maybe,
          color: _hasPermission ? colors.primary : colors.error,
        ),
        title: const Text('输入模拟权限'),
        subtitle: Text(
          _hasPermission
              ? '已授权，可以模拟输入'
              : 'macOS 需要在「系统设置 → 隐私与安全性 → 辅助功能」中授权本应用',
        ),
        trailing: FilledButton.tonal(
          onPressed: _requestPermission,
          child: const Text('检查'),
        ),
      ),
    );
  }

  Widget _delayCard() {
    return _section(
      icon: Icons.timer_outlined,
      title: '发送前延时',
      subtitle: _busy ? '$_countdown 秒后发送，请切换到目标窗口' : '留出时间把焦点切到接收输入的窗口',
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('立即')),
            ButtonSegment(value: 1, label: Text('1 秒')),
            ButtonSegment(value: 3, label: Text('3 秒')),
            ButtonSegment(value: 5, label: Text('5 秒')),
          ],
          selected: {_delaySeconds},
          onSelectionChanged: _busy
              ? null
              : (selection) => setState(() => _delaySeconds = selection.first),
        ),
      ],
    );
  }

  Widget _keyboardCard() {
    final captured = _capturedKey;
    return _section(
      icon: Icons.keyboard_outlined,
      title: '键盘',
      children: [
        TextField(
          controller: _textController,
          decoration: const InputDecoration(
            labelText: '要输入的文本',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _dispatch(
                    '文本',
                    (instance) => instance.text(text: _textController.text),
                  ),
            icon: const Icon(Icons.text_fields),
            label: const Text('输入文本'),
          ),
        ),
        const Divider(height: 32),
        _keyCaptureField(),
        if (captured != null) ...[
          const SizedBox(height: 12),
          _capturedKeyDetails(captured),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final direction in enigo.Direction.values)
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _dispatch(
                          '按键 ${direction.name}',
                          (instance) =>
                              instance.key(key: captured, direction: direction),
                        ),
                  child: Text(_directionLabel(direction)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _keyCaptureField() {
    final colors = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _keyCaptureFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          setState(() => _capturedKey = event.physicalKey);
        }
        return KeyEventResult.handled;
      },
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: _keyCaptureFocusNode.requestFocus,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: focused ? colors.primary : colors.outlineVariant,
                  width: focused ? 2 : 1,
                ),
              ),
              child: Text(
                focused ? '按下任意一个键…' : '点这里再按键，捕获一个物理按键',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: focused ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// `testKey2Key` 会把按键送进 Rust 再原样送回来，正好用来观察 `Key` 的编解码结果。
  Widget _capturedKeyDetails(PhysicalKeyboardKey captured) {
    PhysicalKeyboardKey? roundTripped;
    String? error;
    try {
      roundTripped = enigo.testKey2Key(key: captured);
    } catch (e) {
      error = '$e';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _keyValueRow('捕获按键', _describeKey(captured)),
        _keyValueRow('经 Rust 往返', error ?? _describeKey(roundTripped!)),
        if (error == null && roundTripped != captured)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '往返后与原按键不同，说明这个键在当前平台上没有对应的 enigo 变体',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _mouseCard() {
    final display = _display;
    final location = _location;
    return _section(
      icon: Icons.mouse_outlined,
      title: '鼠标',
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _keyValueRow(
                    '主显示器',
                    display == null ? '未读取' : '${display.$1} × ${display.$2}',
                  ),
                  _keyValueRow(
                    '指针位置',
                    location == null ? '未读取' : '${location.$1}, ${location.$2}',
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: _readMouseState,
              icon: const Icon(Icons.refresh),
              tooltip: '读取',
            ),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _xController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'X',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _yController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Y',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SegmentedButton<enigo.Coordinate>(
              segments: const [
                ButtonSegment(value: enigo.Coordinate.abs, label: Text('绝对')),
                ButtonSegment(value: enigo.Coordinate.rel, label: Text('相对')),
              ],
              selected: {_coordinate},
              onSelectionChanged: (selection) =>
                  setState(() => _coordinate = selection.first),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _dispatch(
                      '移动鼠标',
                      (instance) => instance.moveMouse(
                        x: _intFieldValue(_xController),
                        y: _intFieldValue(_yController),
                        coordinate: _coordinate,
                      ),
                    ),
              icon: const Icon(Icons.open_with),
              label: const Text('移动'),
            ),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _mouseButton,
                decoration: const InputDecoration(
                  labelText: '按键',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final button in _mouseButtons)
                    DropdownMenuItem(value: button, child: Text(button)),
                ],
                onChanged: (value) =>
                    setState(() => _mouseButton = value ?? 'left'),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _dispatch(
                      '鼠标点击',
                      (instance) => instance.button(
                        button: enigo.Button(value: _mouseButton),
                        direction: enigo.Direction.click,
                      ),
                    ),
              icon: const Icon(Icons.ads_click),
              label: const Text('点击'),
            ),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _scrollLengthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '滚动格数',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SegmentedButton<enigo.Axis>(
              segments: const [
                ButtonSegment(value: enigo.Axis.vertical, label: Text('垂直')),
                ButtonSegment(value: enigo.Axis.horizontal, label: Text('水平')),
              ],
              selected: {_axis},
              onSelectionChanged: (selection) =>
                  setState(() => _axis = selection.first),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _dispatch(
                      '滚动',
                      (instance) => instance.scroll(
                        length: _intFieldValue(_scrollLengthController),
                        axis: _axis,
                      ),
                    ),
              icon: const Icon(Icons.swap_vert),
              label: const Text('滚动'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _keyValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  String _describeKey(PhysicalKeyboardKey key) {
    final usage = key.usbHidUsage.toRadixString(16).padLeft(8, '0');
    return '${key.debugName ?? 'Unknown'} (0x$usage)';
  }

  String _directionLabel(enigo.Direction direction) => switch (direction) {
    enigo.Direction.press => '按下',
    enigo.Direction.release => '抬起',
    enigo.Direction.click => '点击',
  };
}
