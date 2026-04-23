import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../util/random_password.dart';
import '../../util/route.dart';
import '../../widget/match_text.dart';
import '../../i18n.dart';
import '../../widget/extension_state.dart';

class _GenPasswordArgs extends PageRouteArgs {
  _GenPasswordArgs({super.key, this.popPassword = false});
  final bool popPassword;
}

class GenPasswordRoute extends PageRouteInfo<_GenPasswordArgs> {
  GenPasswordRoute({Key? key, bool popPassword = false})
    : super(
        name,
        args: _GenPasswordArgs(key: key, popPassword: popPassword),
      );

  static const name = "GenPasswordRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_GenPasswordArgs>(
        orElse: () => _GenPasswordArgs(),
      );
      return GenPasswordPage(key: args.key, popPassword: args.popPassword);
    },
  );
}

class GenPasswordPage extends StatefulWidget {
  const GenPasswordPage({super.key, this.popPassword = false});

  final bool popPassword;

  @override
  State<GenPasswordPage> createState() => _GenPasswordPageState();
}

class _GenPasswordPageState extends State<GenPasswordPage> {
  late final HighlightTextEditingController _controller =
      HighlightTextEditingController();

  bool _includeLetterLow = true;
  bool _includeLetterUp = true;
  bool _includeNumber = true;
  bool _includeSymbol = true;
  bool _includeBrackets = true;
  String _customText = "";

  double _length = 10;
  late String _password;
  late int _entropy;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (_controller.text != _password) {
        _password = _controller.text;
        _entropy = passwordEntropy(_controller.text);
        setState(() {});
      }
    });

    _updatePassword();
  }

  void _updatePassword() {
    final charSet = [
      if (_includeLetterLow) CharacterSet.lowerCaseLetters,
      if (_includeLetterUp) CharacterSet.upperCaseLetters,
      if (_includeNumber) CharacterSet.numbers,
      if (_includeSymbol) CharacterSet.symbols,
      if (_includeBrackets) CharacterSet.brackets,
      _customText,
    ];

    _password = randomPassword(length: _length.toInt(), charSet: charSet);
    _entropy = passwordEntropy(_password, charSet.join());

    _controller.text = _password;

    setState(() {});
  }

  void _cahnged({
    bool? includeNumber,
    bool? includeSymbol,
    bool? includeLetterLow,
    bool? includeLetterUp,
    bool? includeBrackets,
  }) {
    includeNumber ??= _includeNumber;
    includeSymbol ??= _includeSymbol;
    includeLetterLow ??= _includeLetterLow;
    includeLetterUp ??= _includeLetterUp;
    includeBrackets ??= _includeBrackets;

    if (!includeNumber &&
        !includeSymbol &&
        !includeLetterLow &&
        !includeLetterUp &&
        !includeBrackets) {
      return;
    }

    _includeNumber = includeNumber;
    _includeLetterLow = includeLetterLow;
    _includeLetterUp = includeLetterUp;
    _includeSymbol = includeSymbol;
    _includeBrackets = includeBrackets;

    _updatePassword();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    _controller.matchs = [
      MatchHighlightItem(
        regExp: RegExp(r"[a-zA-Z]+"),
        style: Theme.of(context).textTheme.bodyLarge!,
      ),
      MatchHighlightItem(
        regExp: RegExp(r"\d+"),
        style: Theme.of(
          context,
        ).textTheme.bodyLarge!.copyWith(color: Colors.blue),
      ),
      MatchHighlightItem(
        regExp: RegExp(r"[\(\)\[\]\{\}<>]+"),
        style: Theme.of(
          context,
        ).textTheme.bodyLarge!.copyWith(color: Colors.amberAccent),
      ),
      if (_customText.isNotEmpty)
        MatchHighlightItem(
          regExp: RegExp(
            "[${RegExp.escape(Set.from(_customText.split("")).join())}]+",
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: Colors.green),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.popPassword,
        title: Text(t.gen_password),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: _cardColumn([
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.password_rounded),
                ),
                Text(t.password, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  enableSuggestions: false,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(color: Colors.red),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    label: Row(
                      mainAxisSize: .min,
                      spacing: 6,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _entropy < 32
                                ? Colors.red
                                : _entropy < 56
                                ? Colors.amber
                                : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Text(
                          "$_entropy bit",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: IconButton(
                        onPressed: _updatePassword,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  ),
                ),

                Row(
                  spacing: 0,
                  children: [
                    Expanded(
                      child: Slider(
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
                    ),
                    SizedBox(width: 30, child: Text("${_length.toInt()}")),
                  ],
                ),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _cahnged(includeLetterLow: !_includeLetterLow);
                      },
                      style: TextButton.styleFrom(
                        side: _includeLetterLow
                            ? BorderSide(color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      child: Text("a-z"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _cahnged(includeLetterUp: !_includeLetterUp);
                      },
                      style: TextButton.styleFrom(
                        side: _includeLetterUp
                            ? BorderSide(color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      child: Text("A-Z"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _cahnged(includeNumber: !_includeNumber);
                      },
                      style: TextButton.styleFrom(
                        side: _includeNumber
                            ? BorderSide(color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      child: Text("0-9"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _cahnged(includeSymbol: !_includeSymbol);
                      },
                      style: TextButton.styleFrom(
                        side: _includeSymbol
                            ? BorderSide(color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      child: Text(CharacterSet.symbols),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _cahnged(includeBrackets: !_includeBrackets);
                      },
                      style: TextButton.styleFrom(
                        side: _includeBrackets
                            ? BorderSide(color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      child: Text(CharacterSet.brackets),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsetsGeometry.symmetric(vertical: 12),
                  child: TextField(
                    onEditingComplete: () {
                      _updatePassword();
                    },
                    onChanged: (value) => _customText = value,
                    decoration: InputDecoration(
                      labelText: t.custom,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: const ValueKey("gen_password_float"),
        onPressed: () {
          if (widget.popPassword) {
            context.router.pop(_controller.text);
          } else {
            writeClipboard(_controller.text);
          }
        },
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(56 / 2)),
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
      child: ClipRRect(
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Column(spacing: 12, children: children),
        ),
      ),
    );
  }
}
