import 'dart:async';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  GlobalKey<FormState>? _from;
  UpdateMeta _updateMeta = UpdateMeta();
  KdbxConfig _kdbxConfig = KdbxConfig(
    outerCipherConfig: .aes256,
    compressionConfig: .gZip,
    innerCipherConfig: .chaCha20,
    kdfConfig: .aes(rounds: 2),
  );

  bool _isDirty = false;

  bool _isKdfAes = true;

  int _rounds = 2;
  int _iterations = 2;
  int _memory = 1048576;
  int _parallelism = 1;
  Argon2Version _argonVersion = .version13;

  @override
  void initState() {
    _getSettings();
    super.initState();
  }

  Future<void> _getSettings() async {
    try {
      _updateMeta = await Store.kdbx.kdbx!.getUpdateMeta();
      _kdbxConfig = await Store.kdbx.kdbx!.getConfig();

      _isKdfAes = false;

      switch (_kdbxConfig.kdfConfig) {
        case KdfConfig_Aes(rounds: final rounds):
          _isKdfAes = true;
          _rounds = rounds;
          break;
        case KdfConfig_Argon2(
          iterations: final iterations,
          memory: final memory,
          parallelism: final parallelism,
          version: final version,
        ):
          _iterations = iterations;
          _memory = memory;
          _parallelism = parallelism;
          _argonVersion = version;
          break;
        case KdfConfig_Argon2id(
          iterations: final iterations,
          memory: final memory,
          parallelism: final parallelism,
          version: final version,
        ):
          _iterations = iterations;
          _memory = memory;
          _parallelism = parallelism;
          _argonVersion = version;
          break;
      }

      _from = GlobalKey();
      setState(() {});
    } catch (e, s) {
      showError(e, s);
    }
  }

  Future<void> _save() async {
    _from!.currentState!.save();
    if (await kdbxActions([
      .updateMeta(_updateMeta),
      .updateConfig(
        compressionConfig: _kdbxConfig.compressionConfig,
        outerCipherConfig: _kdbxConfig.outerCipherConfig,
        innerCipherConfig: _kdbxConfig.innerCipherConfig,
        kdfConfig: _kdbxConfig.kdfConfig,
      ),
    ])) {
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
                    onSaved: (value) => _updateMeta.defaultUsername =
                        value?.isNotEmpty == true ? value : null,
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
                      _CalculateType.add => min((value ?? 14) + 1, 999),
                      _CalculateType.reduce => max((value ?? 15) - 1, 1),
                    };
                  },
                ),
                _RangeSelectionFormField(
                  canDisable: true,
                  label: "强制修改主密码天数",
                  initialValue: _updateMeta.masterKeyChangeForce ?? 30,
                  onSaved: (value) => _updateMeta.masterKeyChangeForce = value,
                  formatText: (value) {
                    if (value == -1) {
                      return t.none;
                    }
                    return t.days(value!);
                  },
                  onCalculate: (value, type) {
                    return switch (type) {
                      _CalculateType.add => min((value ?? 29) + 1, 999),
                      _CalculateType.reduce => max((value ?? 31) - 1, 1),
                    };
                  },
                ),


                // TODO! 暂不考虑
                // _RangeSelectionFormField(
                //   canDisable: true,
                //   label: "历史记录维护天数",
                //   initialValue: _updateMeta.maintenanceHistoryDays ?? -1,
                //   onSaved: (value) => _updateMeta.maintenanceHistoryDays =
                //       value != null && value > 0 ? value : null,
                //   formatText: (value) {
                //     if (value == -1) {
                //       return t.none;
                //     }
                //     return t.days(value!);
                //   },
                //   onCalculate: (value, type) {
                //     return switch (type) {
                //       _CalculateType.add => min((value ?? 29) + 1, 999),
                //       _CalculateType.reduce => max((value ?? 31) - 1, 1),
                //     };
                //   },
                // ),

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
                      _CalculateType.add => min((value ?? 19) + 1, 999),
                      _CalculateType.reduce => max((value ?? 21) - 1, 1),
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
                      _CalculateType.reduce => max(
                        (value ?? mb1 * 2) - mb1,
                        mb1,
                      ),
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
                        child: Icon(Icons.enhanced_encryption),
                      ),
                      Text(
                        "加密配置",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<CompressionConfig>(
                    initialValue: _kdbxConfig.compressionConfig,
                    items: [
                      DropdownMenuItem(value: .gZip, child: Text("GZip")),
                      DropdownMenuItem(value: .none, child: Text("None")),
                    ],
                    decoration: InputDecoration(
                      labelText: "压缩",
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {},
                    onSaved: (value) {
                      _kdbxConfig.compressionConfig =
                          value ?? _kdbxConfig.compressionConfig;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<OuterCipherConfig>(
                    initialValue: _kdbxConfig.outerCipherConfig,
                    items: [
                      DropdownMenuItem(value: .aes256, child: Text("AES 256")),
                      DropdownMenuItem(
                        value: .chaCha20,
                        child: Text("ChaCha20"),
                      ),
                      DropdownMenuItem(value: .twofish, child: Text("Twofish")),
                    ],
                    decoration: InputDecoration(
                      labelText: "加密算法",
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {},
                    onSaved: (value) {
                      _kdbxConfig.outerCipherConfig =
                          value ?? _kdbxConfig.outerCipherConfig;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<InnerCipherConfig>(
                    initialValue: _kdbxConfig.innerCipherConfig,
                    items: [
                      DropdownMenuItem(
                        value: .chaCha20,
                        child: Text("ChaCha20"),
                      ),
                      DropdownMenuItem(value: .salsa20, child: Text("Salsa20")),
                      DropdownMenuItem(value: .plain, child: Text("Plain")),
                    ],
                    decoration: InputDecoration(
                      labelText: "内联加密算法",
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {},
                    onSaved: (value) {
                      _kdbxConfig.innerCipherConfig =
                          value ?? _kdbxConfig.innerCipherConfig;
                    },
                  ),
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
                        child: Icon(Icons.enhanced_encryption),
                      ),
                      Text(
                        "KDF配置",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<KdfConfig>(
                    initialValue: _kdbxConfig.kdfConfig,
                    items: [
                      DropdownMenuItem(
                        value: _kdbxConfig.kdfConfig is KdfConfig_Argon2
                            ? _kdbxConfig.kdfConfig
                            : KdfConfig_Argon2(
                                iterations: _iterations,
                                memory: _memory,
                                parallelism: _parallelism,
                                version: _argonVersion,
                              ),
                        child: Text("Argon2d"),
                      ),
                      DropdownMenuItem(
                        value: _kdbxConfig.kdfConfig is KdfConfig_Argon2id
                            ? _kdbxConfig.kdfConfig
                            : KdfConfig_Argon2id(
                                iterations: _iterations,
                                memory: _memory,
                                parallelism: _parallelism,
                                version: _argonVersion,
                              ),
                        child: Text("Argon2id"),
                      ),
                      DropdownMenuItem(
                        value: _kdbxConfig.kdfConfig is KdfConfig_Aes
                            ? _kdbxConfig.kdfConfig
                            : KdfConfig_Aes(rounds: _rounds),
                        child: Text("AES-KDF"),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: "密钥导出函数",
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _isKdfAes = value is KdfConfig_Aes;
                      setState(() {});
                    },
                    onSaved: (value) {
                      _kdbxConfig.kdfConfig = switch (value!) {
                        KdfConfig_Aes() => KdfConfig_Aes(rounds: _rounds),
                        KdfConfig_Argon2() => KdfConfig_Argon2(
                          iterations: _iterations,
                          memory: _memory,
                          parallelism: _parallelism,
                          version: _argonVersion,
                        ),
                        KdfConfig_Argon2id() => KdfConfig_Argon2id(
                          iterations: _iterations,
                          memory: _memory,
                          parallelism: _parallelism,
                          version: _argonVersion,
                        ),
                      };
                    },
                  ),
                ),

                if (_isKdfAes)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      key: ValueKey("rounds"),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      initialValue: _rounds.toString(),
                      onChanged: (value) {
                        _rounds = max(int.tryParse(value) ?? 1, 1);
                      },
                      decoration: InputDecoration(
                        labelText: "转换次数",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                if (!_isKdfAes) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      key: ValueKey("iterations"),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      initialValue: _iterations.toString(),
                      onChanged: (value) {
                        _iterations = max(int.tryParse(value) ?? 1, 1);
                      },
                      decoration: InputDecoration(
                        labelText: "转换次数",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  _RangeSelectionFormField(
                    label: "内存占用",
                    initialValue: _memory,
                    onChanged: (value) {
                      _memory = value ?? _memory;
                    },
                    formatText: (value) {
                      return (value ?? 1).toStorageUnit(.MB);
                    },
                    onCalculate: (value, type) {
                      final mb1 = 1048576;
                      return switch (type) {
                        _CalculateType.add => min(
                          (value ?? 0) + mb1,
                          104857600,
                        ),
                        _CalculateType.reduce => max((value ?? mb1) - mb1, mb1),
                      };
                    },
                  ),

                  _RangeSelectionFormField(
                    label: "并行计算",
                    initialValue: _parallelism,
                    onChanged: (value) {
                      _parallelism = value ?? _parallelism;
                    },
                    formatText: (value) {
                      return "$value";
                    },
                    onCalculate: (value, type) {
                      return switch (type) {
                        _CalculateType.add => min((value ?? 0) + 1, 16),
                        _CalculateType.reduce => max((value ?? 2) - 1, 1),
                      };
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<Argon2Version>(
                      initialValue: _argonVersion,
                      items: [
                        DropdownMenuItem(value: .version10, child: Text("10")),
                        DropdownMenuItem(value: .version13, child: Text("13")),
                      ],
                      decoration: InputDecoration(
                        labelText: "Argon2 版本",
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _argonVersion = value ?? _argonVersion;
                      },
                    ),
                  ),
                ],
              ]),

              SizedBox(height: 56),
            ],
          ),
        ),
      ),

      floatingActionButton: _isDirty
          ? FloatingActionButton(
              heroTag: const ValueKey("kdbx_setting_float"),
              onPressed: singleTrigger(_save),
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
    this.onChanged,
  });

  final String? label;
  final _RangeSelectionFormatText formatText;
  final _RangeSelectionCalculate onCalculate;
  final bool canDisable;
  final int? initialValue;
  final FormFieldSetter<int>? onSaved;
  final FormFieldSetter<int>? onChanged;

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
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => action());
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
          widget.onChanged?.call(value);
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
                          field.didChange(
                            _prevValue != null && _prevValue! > 0
                                ? _prevValue
                                : onCalculate(null, .add),
                          );
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
                                  didChange(onCalculate(field.value, .add));
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
                                  didChange(onCalculate(field.value, .reduce));
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
