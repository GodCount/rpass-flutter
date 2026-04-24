import 'package:flutter/material.dart';

class MatchHighlightItem {
  const MatchHighlightItem({required this.regExp, required this.style});

  final RegExp regExp;
  final TextStyle style;

  bool hasMatch(String text) => regExp.hasMatch(text);

  (List<(int, int)>, TextStyle?) allMatches(String text) {
    final matchs = regExp.allMatches(text).toList();
    return (matchs.map((item) => (item.start, item.end)).toList(), style);
  }
}

class MatchTextSpan {
  const MatchTextSpan({required this.text, required this.matchs, this.style});
  final String text;
  final List<MatchHighlightItem> matchs;
  final TextStyle? style;

  TextSpan build() {
    return TextSpan(style: style, children: _matchText());
  }

  List<TextSpan> _matchText() {
    final List<TextSpan> children = [];
    final List<(int, int, TextStyle)> allMatches = [];

    for (final matchItem in matchs) {
      if (!matchItem.hasMatch(text)) continue;
      for (final match in matchItem.regExp.allMatches(text)) {
        allMatches.add((match.start, match.end, matchItem.style));
      }
    }

    allMatches.sort((a, b) => a.$1.compareTo(b.$1));

    int lastEnd = 0;
    for (final (start, end, style) in allMatches) {
      if (start < lastEnd) continue; // Skip overlapping matches
      if (start > lastEnd) {
        children.add(TextSpan(text: text.substring(lastEnd, start)));
      }
      children.add(TextSpan(text: text.substring(start, end), style: style));
      lastEnd = end;
    }

    if (lastEnd < text.length) {
      children.add(TextSpan(text: text.substring(lastEnd)));
    }

    return children;
  }
}

class MatchText extends StatelessWidget {
  const MatchText({
    super.key,
    required this.text,
    required this.matchs,
    this.style,
  });

  final String text;
  final List<MatchHighlightItem> matchs;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: MatchTextSpan(text: text, matchs: matchs, style: style).build(),
    );
  }
}

class HighlightTextEditingController extends TextEditingController {
  HighlightTextEditingController({List<MatchHighlightItem>? matchs, super.text})
    : _matchs = matchs ?? [];

  List<MatchHighlightItem> _matchs;

  // ignore: unnecessary_getters_setters
  List<MatchHighlightItem> get matchs => _matchs;

  set matchs(List<MatchHighlightItem> newMatchs) {
    _matchs = newMatchs;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return MatchTextSpan(text: text, matchs: matchs, style: style).build();
  }
}
