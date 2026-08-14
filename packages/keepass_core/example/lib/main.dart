import 'package:flutter/material.dart';
// kdbx 的 `Icon` 与 Flutter 的 `Icon` 重名，这里只需要初始化入口。
import 'package:keepass_core/keepass_core.dart' show initRustLib;

import 'example_module.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initRustLib();
  runApp(const KdbxdbExampleApp());
}

class KdbxdbExampleApp extends StatelessWidget {
  const KdbxdbExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kdbxdb example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const ExampleHomePage(),
    );
  }
}

/// 模块选择页，列出 [exampleModules] 里注册的所有示例。
class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('kdbxdb 示例')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: exampleModules.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final module = exampleModules[index];
          return ListTile(
            leading: CircleAvatar(child: Icon(module.icon)),
            title: Text(module.title),
            subtitle: Text(module.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: module.builder)),
          );
        },
      ),
    );
  }
}
