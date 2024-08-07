import 'package:flutter/material.dart';

class MatchHighlight {
  const MatchHighlight({required this.regExp, this.style});
  final RegExp regExp;
  final TextStyle? style;

  bool hasMatch(String text) => regExp.hasMatch(text);

  (List<(int, int)>, TextStyle?) allMatches(String text) {
    final matchs = regExp.allMatches(text).toList();
    return (matchs.map((item) => (item.start, item.end)).toList(), style);
  }
}

class MatchText extends StatelessWidget {
  const MatchText({
    super.key,
    required this.text,
    required this.matchs,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.overflow = TextOverflow.clip,
    this.textScaler = TextScaler.noScaling,
    this.maxLines,
  });

  final String text;
  final List<MatchHighlight> matchs;
  final TextStyle? style;

  final TextAlign textAlign;
  final TextDirection? textDirection;
  final TextOverflow overflow;
  final TextScaler textScaler;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign,
      textDirection: textDirection,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      text: TextSpan(
        style: style,
        children: matchTexts(),
      ),
    );
  }

  @protected
  List<TextSpan> matchTexts({List<MatchHighlight>? matchs, TextStyle? style}) {
    matchs ??= this.matchs;
    style ??= this.style;

    final list = matchs.where((item) => item.hasMatch(text));
    if (list.isEmpty) return [TextSpan(text: text)];

    final regexps = list.map((item) => item.allMatches(text)).toList();

    final List<((int, int), TextSpan)> results = [];

    for (var item in regexps) {
      for (var postion in item.$1) {
        results.add((
          postion,
          TextSpan(style: item.$2, text: text.substring(postion.$1, postion.$2))
        ));
      }
    }

    results.sort((a, b) => a.$1.$1 - b.$1.$1);

    if (results.first.$1.$1 != 0) {
      results.insert(0, (
        (0, results.first.$1.$1),
        TextSpan(style: style, text: text.substring(0, results.first.$1.$1))
      ));
    }

    if (results.last.$1.$2 != text.length) {
      results.add((
        (results.last.$1.$2, text.length),
        TextSpan(
          style: style,
          text: text.substring(results.last.$1.$2, text.length),
        )
      ));
    }

    for (var i = results.length - 2; i >= 0; i--) {
      if (results[i].$1.$2 != results[i + 1].$1.$1) {
        results.insert(i + 1, (
          (results[i].$1.$2, results[i + 1].$1.$1),
          TextSpan(
            style: style,
            text: text.substring(results[i].$1.$2, results[i + 1].$1.$1),
          )
        ));
      }
    }
    return results.map((item) => item.$2).toList();
  }
}
