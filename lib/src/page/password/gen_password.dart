import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../util/route.dart';
import '../../widget/match_text.dart';
import '../../i18n.dart';
import '../../util/common.dart';
import '../../widget/extension_state.dart';

class _GenPasswordArgs extends PageRouteArgs {
  _GenPasswordArgs({
    super.key,
    this.popPassword = false,
  });
  final bool popPassword;
}

class GenPasswordRoute extends PageRouteInfo<_GenPasswordArgs> {
  GenPasswordRoute({
    Key? key,
    bool popPassword = false,
  }) : super(
          name,
          args: _GenPasswordArgs(
            key: key,
            popPassword: popPassword,
          ),
        );

  static const name = "GenPasswordRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_GenPasswordArgs>(
        orElse: () => _GenPasswordArgs(),
      );
      return GenPasswordPage(
        key: args.key,
        popPassword: args.popPassword,
      );
    },
  );
}

class GenPasswordPage extends StatefulWidget {
  const GenPasswordPage({
    super.key,
    this.popPassword = false,
  });

  final bool popPassword;

  @override
  State<GenPasswordPage> createState() => _GenPasswordPageState();
}

class _GenPasswordPageState extends State<GenPasswordPage> {
  bool _enableLetterLow = true;
  bool _enableLetterUp = true;
  bool _enableNumber = true;
  bool _enableSymbol = true;
  bool _enableCustom = false;
  String _customText = "";

  double _length = 10;

  late String password;
  late int entropy;

  void _updatePassword() {
    final value = randomPassword(
      length: _length.toInt(),
      enableNumber: _enableNumber,
      enableSymbol: _enableSymbol,
      enableLetterLowercase: _enableLetterLow,
      enableLetterUppercase: _enableLetterUp,
      customText: _enableCustom ? _customText : null,
    );
    password = value.$1;
    entropy = value.$2;
    setState(() {});
  }

  void _cahnged({
    bool? enableNumber,
    bool? enableSymbol,
    bool? enableLetterLow,
    bool? enableLetterUp,
    bool? enableCustom,
  }) {
    enableNumber ??= _enableNumber;
    enableSymbol ??= _enableSymbol;
    enableLetterLow ??= _enableLetterLow;
    enableLetterUp ??= _enableLetterUp;
    enableCustom ??= _enableCustom;

    if (!enableNumber &&
        !enableSymbol &&
        !enableLetterLow &&
        !enableLetterUp &&
        !enableCustom) {
      return;
    }

    _enableNumber = enableNumber;
    _enableLetterLow = enableLetterLow;
    _enableLetterUp = enableLetterUp;
    _enableSymbol = enableSymbol;
    _enableCustom = enableCustom;
    _updatePassword();
  }

  @override
  void initState() {
    super.initState();
    _updatePassword();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(12.0),
        bottomRight: Radius.circular(12.0),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.popPassword,
        title: Text(t.gen_password),
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
                    child: Icon(Icons.password_rounded),
                  ),
                  Text(
                    t.password,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: Container(
                alignment: Alignment.centerLeft,
                child: MatchText(
                  text: password,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(color: Colors.red),
                  matchs: [
                    MatchHighlightItem(
                      regExp: RegExp(r"[a-zA-Z]+"),
                      style: Theme.of(context).textTheme.bodyLarge!,
                    ),
                    MatchHighlightItem(
                      regExp: RegExp(r"\d+"),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(color: Colors.blue),
                    ),
                    if (_customText.isNotEmpty)
                      MatchHighlightItem(
                        regExp: RegExp(
                          "[${Set.from(_customText.split("")).join()}]+",
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(color: Colors.green),
                      )
                  ],
                ),
              ),
              // subtitle: const SizedBox(),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _updatePassword,
              ),
            ),
            ListTile(
              shape: shape,
              title: LinearProgressIndicator(
                value: entropy.toDouble() / 100,
                minHeight: 24,
                color: entropy < 32
                    ? Colors.red
                    : entropy < 56
                        ? Colors.amber
                        : Colors.green,
                borderRadius: const BorderRadius.all(
                  Radius.circular(4),
                ),
              ),
              trailing: SizedBox(
                width: 64,
                child: Text(
                  "$entropy bit",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.straighten),
                  ),
                  Text(
                    t.pass_length,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: Slider(
                value: _length,
                min: 4,
                max: 128,
                onChanged: (value) {
                  setState(() {
                    _length = value;
                  });
                },
                onChangeEnd: (length) => _updatePassword(),
              ),
              trailing: Text("${_length.toInt()}"),
            ),
          ]),
          _cardColumn(
            [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.onetwothree),
                    ),
                    Text(
                      t.include_cahr,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text("${t.letter} (abc)"),
                trailing: _enableLetterLow ? const Icon(Icons.check) : null,
                onTap: () {
                  _cahnged(enableLetterLow: !_enableLetterLow);
                },
              ),
              ListTile(
                title: Text("${t.letter} (ABC)"),
                trailing: _enableLetterUp ? const Icon(Icons.check) : null,
                onTap: () {
                  _cahnged(enableLetterUp: !_enableLetterUp);
                },
              ),
              ListTile(
                title: Text("${t.number} (01)"),
                trailing: _enableNumber ? const Icon(Icons.check) : null,
                onTap: () {
                  _cahnged(enableNumber: !_enableNumber);
                },
              ),
              ListTile(
                title: Text("${t.special_char} (!@)"),
                trailing: _enableSymbol ? const Icon(Icons.check) : null,
                onTap: () {
                  _cahnged(enableSymbol: !_enableSymbol);
                },
              ),
              ListTile(
                title: Text(t.custom),
                trailing: _enableCustom ? const Icon(Icons.check) : null,
                onTap: () {
                  _cahnged(enableCustom: !_enableCustom);
                },
              ),
              ListTile(
                shape: shape,
                title: TextField(
                  onEditingComplete: () {
                    if (_customText.isEmpty &&
                        !_enableNumber &&
                        !_enableSymbol &&
                        !_enableLetterLow &&
                        !_enableLetterUp) {
                      _cahnged(
                        enableNumber: true,
                        enableSymbol: true,
                        enableLetterLow: true,
                        enableLetterUp: true,
                        enableCustom: false,
                      );
                    } else {
                      _updatePassword();
                    }
                  },
                  onChanged: (value) => _customText = value,
                  enabled: _enableCustom,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                subtitle: SizedBox(height: 6,),
              )
            ],
          ),
          const SizedBox(height: 56)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: const ValueKey("gen_password_float"),
        onPressed: () {
          if (widget.popPassword) {
            context.router.pop(password);
          } else {
            writeClipboard(password);
          }
        },
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        child: Icon(widget.popPassword ? Icons.done : Icons.copy),
      ),
    );
  }

  Widget _cardColumn(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
