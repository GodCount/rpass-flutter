import 'package:flutter/material.dart';

import 'examples/enigo_example.dart';
import 'examples/kdbx_example.dart';

/// 一个示例模块在选择页上的描述。
@immutable
class ExampleModule {
  const ExampleModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
}

/// 所有示例模块。新增一个模块时，在 `examples/` 下写好页面，再往这个列表里追加一项即可。
const List<ExampleModule> exampleModules = <ExampleModule>[
  ExampleModule(
    title: 'Enigo',
    description: '模拟键盘与鼠标输入，并查看物理按键的编解码结果',
    icon: Icons.keyboard_alt_outlined,
    builder: buildEnigoExample,
  ),
  ExampleModule(
    title: 'Kdbx',
    description: '新建或打开数据库，浏览分组与条目，增删改并保存',
    icon: Icons.lock_outline,
    builder: buildKdbxExample,
  ),
];
