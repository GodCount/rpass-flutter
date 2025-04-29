import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
import '../../kdbx/kdbx.dart';


class _KdbxSettingArgs extends PageRouteArgs {
  _KdbxSettingArgs({super.key});
}

class KdbxSettingRoute extends PageRouteInfo<_KdbxSettingArgs> {
  KdbxSettingRoute({
    Key? key,
  }) : super(
          name,
          args: _KdbxSettingArgs(key: key),
        );

  static const name = "KdbxSettingRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_KdbxSettingArgs>(
        orElse: () => _KdbxSettingArgs(),
      );
      return KdbxSettingPage(key: args.key);
    },
  );
}

class KdbxSettingPage extends StatefulWidget {
  const KdbxSettingPage({super.key});

  @override
  State<KdbxSettingPage> createState() => _KdbxSettingPageState();
}

class _KdbxSettingPageState extends State<KdbxSettingPage>
    with SecondLevelPageAutoBack<KdbxSettingPage> {
  int _historyMaxItems = 20;
  int _historyMaxSize = 10;

  bool _isDirty = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      final kdbx = KdbxProvider.of(context)!;
      _historyMaxItems = kdbx.historyMaxItems;
      _historyMaxSize = _b2mb(kdbx.historyMaxSize).toInt();
      setState(() {});
    });
    super.initState();
  }

  double _b2mb(num size) {
    return size / (1024 * 1024);
  }

  double _mb2b(num size) {
    return size * 1024 * 1024;
  }

  void _save() async {
    final kdbx = KdbxProvider.of(context)!;
    kdbx.historyMaxItems = _historyMaxItems;
    kdbx.historyMaxSize = _mb2b(_historyMaxSize).toInt();
    if (await kdbxSave(kdbx)) {
      context.router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.pass_lib_setting),
      ),
      body: ListView(
        padding: const EdgeInsets.all(6),
        children: [
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.history_rounded),
                  ),
                  Text(t.history_record,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: Text(t.max_count),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _historyMaxItems.toDouble(),
                      divisions: 128,
                      min: 1,
                      max: 128,
                      onChanged: (value) {
                        setState(() {
                          _isDirty = true;
                          _historyMaxItems = value.toInt();
                        });
                      },
                    ),
                  ),
                  Text(_historyMaxItems.toString())
                ],
              ),
            ),
            ListTile(
              title: Text(t.max_size),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _historyMaxSize * 10.0,
                      divisions: 320,
                      min: 10,
                      max: 320,
                      onChanged: (value) {
                        setState(() {
                          _isDirty = true;
                          _historyMaxSize = (value / 10.0).toInt();
                        });
                      },
                    ),
                  ),
                  Text("$_historyMaxSize MB")
                ],
              ),
            ),
          ]),
        ],
      ),
      floatingActionButton: _isDirty
          ? FloatingActionButton(
              heroTag: const ValueKey("kdbx_setting_float"),
              onPressed: _save,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(56 / 2),
                ),
              ),
              child: const Icon(Icons.save),
            )
          : null,
    );
  }

  Widget _cardColumn(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6.0)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
