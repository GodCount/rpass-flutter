import 'dart:async';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';

import '../../i18n.dart';
import '../../store/index.dart';
import '../../util/common.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
import '../../widget/form.dart';

class _KdbxSettingArgs extends PageRouteArgs {
  _KdbxSettingArgs({super.key});
}

class KdbxSettingRoute extends PageRouteInfo<_KdbxSettingArgs> {
  KdbxSettingRoute({Key? key}) : super(name, args: _KdbxSettingArgs(key: key));

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
  final GlobalKey<FormState> _from = GlobalKey();
  UpdateMeta _updateMeta = UpdateMeta();
  // KdbxConfig? _kdbxConfig;

  bool _isDirty = false;

  @override
  void initState() {
    _getSettings();
    super.initState();
  }

  Future<void> _getSettings() async {
    try {
      _updateMeta = await Store.kdbx.kdbx!.getUpdateMeta();
    } catch (e, s) {
      showError(e, s);
    }
  }

  void _save() async {}

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.pass_lib_setting),
      ),
      body: Form(
        key: _from,
        onChanged: () {
          if (!_isDirty) {
            setState(() {
              _isDirty = true;
            });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: Column(
            children: [
              _cardColumn([
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.edit_document),
                      ),
                      Text(
                        "基本配置",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    initialValue: _updateMeta.databaseName,
                    onSaved: (value) => _updateMeta.databaseName = value,
                    decoration: InputDecoration(
                      labelText: "数据库名称",
                      border: const OutlineInputBorder(),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ColorFormField(
                          initialValue:
                              _updateMeta.color ??
                              Store.settings.themeSeedColor,
                          onSaved: (value) => _updateMeta.color = value,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    initialValue: _updateMeta.databaseDescription,
                    decoration: InputDecoration(
                      labelText: t.description,
                      border: const OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    onSaved: (value) => _updateMeta.databaseDescription = value,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    initialValue: _updateMeta.defaultUsername,
                    onSaved: (value) => _updateMeta.defaultUsername = value,
                    decoration: InputDecoration(
                      labelText: "默认用户名",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),

                SelectGroupFormField(
                  noRoot: true,
                  isDelete: true,
                  label: "模版组",
                  initialValue: _updateMeta.entryTemplatesGroup != null
                      ? Store.kdbx.getGroup(_updateMeta.entryTemplatesGroup!)
                      : null,
                  onSaved: (value) =>
                      _updateMeta.entryTemplatesGroup = value?.id,
                ),

                _RangeSelectionFormField(
                  canDisable: true,
                  label: "历史记录维护天数",
                  initialValue: _updateMeta.maintenanceHistoryDays ?? -1,
                  onSaved: (value) => _updateMeta.maintenanceHistoryDays =
                      value != null && value > 0 ? value : null,
                  formatText: (value) {
                    if (value == -1) {
                      return t.none;
                    }
                    return t.days(value!);
                  },
                  onCalculate: (value, type) {
                    return switch (type) {
                      _CalculateType.add => min((value ?? 0) + 1, 999),
                      _CalculateType.reduce => max((value ?? 2) - 1, 1),
                    };
                  },
                ),

                _RangeSelectionFormField(
                  canDisable: true,
                  label: "限制条目的历史记录数",
                  initialValue: _updateMeta.historyMaxItems ?? 20,
                  onSaved: (value) => _updateMeta.historyMaxItems = value,
                  formatText: (value) {
                    if (value == -1) {
                      return t.none;
                    }
                    return "$value";
                  },
                  onCalculate: (value, type) {
                    return switch (type) {
                      _CalculateType.add => min((value ?? 0) + 1, 999),
                      _CalculateType.reduce => max((value ?? 2) - 1, 1),
                    };
                  },
                ),

                _RangeSelectionFormField(
                  canDisable: true,
                  label: "限制每个条目的历史记录总大小",
                  initialValue: _updateMeta.historyMaxSize ?? 10485760,
                  onSaved: (value) => _updateMeta.historyMaxSize = value,
                  formatText: (value) {
                    if (value == -1) {
                      return t.none;
                    }
                    return (value ?? 0).toStorageUnit(.MB);
                  },
                  onCalculate: (value, type) {
                    final mb1 = 1048576;
                    return switch (type) {
                      _CalculateType.add => min((value ?? 0) + mb1, 104857600),
                      _CalculateType.reduce => max((value ?? mb1) - mb1, mb1),
                    };
                  },
                ),
              ]),
              _cardColumn([
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.security),
                      ),
                      Text(
                        "安全配置",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                _RangeSelectionFormField(
                  canDisable: true,
                  label: "建议修改主密码天数",
                  initialValue: _updateMeta.masterKeyChangeRec ?? 15,
                  onSaved: (value) => _updateMeta.masterKeyChangeRec = value,
                  formatText: (value) {
                    if (value == -1) {
                      return t.none;
                    }
                    return t.days(value!);
                  },
                  onCalculate: (value, type) {
                    return switch (type) {
                      _CalculateType.add => min((value ?? 0) + 1, 999),
                      _CalculateType.reduce => max((value ?? 2) - 1, 1),
                    };
                  },
                ),
                _RangeSelectionFormField(
                  canDisable: true,
                  label: "强制修改主密码天数",
                  initialValue: _updateMeta.masterKeyChangeRec ?? 30,
                  onSaved: (value) => _updateMeta.masterKeyChangeRec = value,
                  formatText: (value) {
                    if (value == -1) {
                      return t.none;
                    }
                    return t.days(value!);
                  },
                  onCalculate: (value, type) {
                    return switch (type) {
                      _CalculateType.add => min((value ?? 0) + 1, 999),
                      _CalculateType.reduce => max((value ?? 2) - 1, 1),
                    };
                  },
                ),
              ]),
            ],
          ),
        ),
      ),

      floatingActionButton: _isDirty
          ? FloatingActionButton(
              heroTag: const ValueKey("kdbx_setting_float"),
              onPressed: _save,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(56 / 2)),
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
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      child: ClipRRect(
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Column(spacing: 12, children: children),
        ),
      ),
    );
  }
}

enum _CalculateType { add, reduce }

typedef _RangeSelectionFormatText = String Function(int? value);
typedef _RangeSelectionCalculate =
    int Function(int? value, _CalculateType type);

class _RangeSelectionFormField extends StatefulWidget {
  const _RangeSelectionFormField({
    this.label,
    required this.formatText,
    required this.onCalculate,
    this.canDisable = false,
    this.initialValue,
    this.onSaved,
  });

  final String? label;
  final _RangeSelectionFormatText formatText;
  final _RangeSelectionCalculate onCalculate;
  final bool canDisable;
  final int? initialValue;
  final void Function(int?)? onSaved;

  @override
  State<_RangeSelectionFormField> createState() =>
      _RangeSelectionFormFieldState();
}

class _RangeSelectionFormFieldState extends State<_RangeSelectionFormField> {
  Timer? _timer;
  late int? _prevValue = widget.initialValue;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRepeating(VoidCallback action) {
    action();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => action());
  }

  void _stopRepeating() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      initialValue: widget.initialValue,
      onSaved: widget.onSaved,
      builder: (field) {
        final onCalculate = widget.onCalculate;
        final formatText = widget.formatText;
        final disable = widget.canDisable && field.value == -1;

        final text = formatText(field.value);

        void didChange(int? value) {
          _prevValue = value;
          field.didChange(value);
        }

        return Padding(
          padding: const .only(left: 16, right: 16),
          child: InputDecorator(
            isEmpty: text.isEmpty,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              prefixIcon: widget.canDisable
                  ? Checkbox(
                      value: field.value != -1,
                      onChanged: (value) {
                        if (value == true) {
                          field.didChange(_prevValue ?? onCalculate(0, .add));
                        } else {
                          field.didChange(-1);
                        }
                      },
                    )
                  : null,
              suffixIcon: Padding(
                padding: const .only(right: 7),
                child: SizedBox(
                  width: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      !disable
                          ? InkWell(
                              customBorder: const CircleBorder(),
                              onTapDown: (_) {
                                _startRepeating(() {
                                  didChange(
                                    onCalculate(field.value, .add),
                                  );
                                });
                              },
                              onTapUp: (_) => _stopRepeating(),
                              onTapCancel: _stopRepeating,
                              child: Padding(
                                padding: const .symmetric(vertical: 2),
                                child: Icon(
                                  Icons.expand_less,
                                  size: 18,
                                  color: Colors.grey[700],
                                ),
                              ),
                            )
                          : Padding(
                              padding: const .symmetric(vertical: 2),
                              child: Icon(
                                Icons.expand_less,
                                size: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                      !disable
                          ? InkWell(
                              customBorder: const CircleBorder(),
                              onTapDown: (_) {
                                _startRepeating(() {
                                  didChange(
                                    onCalculate(field.value, .reduce),
                                  );
                                });
                              },
                              onTapUp: (_) => _stopRepeating(),
                              onTapCancel: _stopRepeating,
                              child: Padding(
                                padding: const .symmetric(vertical: 2),
                                child: Icon(
                                  Icons.expand_more,
                                  size: 18,
                                  color: Colors.grey[700],
                                ),
                              ),
                            )
                          : Padding(
                              padding: const .symmetric(vertical: 2),
                              child: Icon(
                                Icons.expand_more,
                                size: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            child: Opacity(opacity: disable ? 0.8 : 1, child: Text(text)),
          ),
        );
      },
    );
  }
}
