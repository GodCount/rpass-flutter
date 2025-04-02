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
      final args = data.argsAs<_GenPasswordArgs>();
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
  bool _enableLetter = true;
  bool _enableNumber = true;
  bool _enableSymbol = true;
  double _length = 10;

  late String password;

  void _updatePassword() {
    password = randomPassword(
      length: _length.toInt(),
      enableNumber: _enableNumber,
      enableSymbol: _enableSymbol,
      enableLetterLowercase: _enableLetter,
      enableLetterUppercase: _enableLetter,
    );
    setState(() {});
  }

  void _cahnged({
    bool? enableNumber,
    bool? enableSymbol,
    bool? enableLetter,
  }) {
    enableNumber ??= _enableNumber;
    enableSymbol ??= _enableSymbol;
    enableLetter ??= _enableLetter;

    if (!enableNumber && !enableSymbol && !enableLetter) {
      return;
    }
    _enableNumber = enableNumber;
    _enableLetter = enableLetter;
    _enableSymbol = enableSymbol;
    _updatePassword();
  }

  @override
  void initState() {
    password = randomPassword(length: _length.toInt());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.0), bottomRight: Radius.circular(6.0)),
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
                  Text(t.password,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              isThreeLine: true,
              title: MatchText(
                text: password,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Colors.red),
                matchs: [
                  MatchHighlight(
                    regExp: RegExp(r"[a-zA-Z]+"),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  MatchHighlight(
                    regExp: RegExp(r"\d+"),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: Colors.blue),
                  )
                ],
              ),
              subtitle: const Text(""),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _updatePassword,
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
                  Text(t.pass_length,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: Slider(
                value: _length,
                divisions: 128,
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
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.onetwothree),
                  ),
                  Text(t.include_cahr,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: Text("${t.letter} (aA)"),
              trailing: _enableLetter ? const Icon(Icons.check) : null,
              onTap: () {
                _cahnged(enableLetter: !_enableLetter);
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
              shape: shape,
              title: Text("${t.special_char} (!@)"),
              trailing: _enableSymbol ? const Icon(Icons.check) : null,
              onTap: () {
                _cahnged(enableSymbol: !_enableSymbol);
              },
            ),
          ])
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
        borderRadius: BorderRadius.all(Radius.circular(6.0)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
