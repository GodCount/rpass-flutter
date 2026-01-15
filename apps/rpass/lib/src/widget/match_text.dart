import 'package:flutter/material.dart';

class MatchHighlightItem {
  const MatchHighlightItem({
    required this.regExp,
    required this.style,
  });

  final RegExp regExp;
  final TextStyle style;

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
  });

  final String text;
  final List<MatchHighlightItem> matchs;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: style,
        children: _matchText(),
      ),
    );
  }

  List<TextSpan> _matchText() {
    final List<TextSpan> children = [];

    final matchList = matchs.where((item) => item.hasMatch(text));

    final regexp = _mergeRegexp(matchList);

    final allMatches = regexp.allMatches(text);

    int lastMatchEnd = 0;

    for (final item in allMatches) {
      final matchStart = item.start;
      final matchEnd = item.end;

      if (matchStart < 0 || matchEnd > text.length) continue;

      if (matchStart > lastMatchEnd) {
        final nonMatchText = text.substring(lastMatchEnd, matchStart);
        children.add(TextSpan(text: nonMatchText));
      }

      final matchText = item.group(0)!;

      final matchedItem = _findMatchedByText(matchText, matchList);
      children.add(TextSpan(text: matchText, style: matchedItem.style));

      lastMatchEnd = matchEnd;
    }

    if (lastMatchEnd < text.length) {
      final remainingText = text.substring(lastMatchEnd);
      children.add(TextSpan(text: remainingText));
    }

    return children;
  }

  RegExp _mergeRegexp(Iterable<MatchHighlightItem> matchs) {
    if (matchs.length == 1) return matchs.first.regExp;

    final StringBuffer buffer = StringBuffer();
    bool first = true;

    for (final item in matchs) {
      if (!first) buffer.write('|');
      buffer.write('(${item.regExp.pattern})');
      first = false;
    }
    return RegExp(buffer.toString());
  }

  MatchHighlightItem _findMatchedByText(
    String text,
    Iterable<MatchHighlightItem> matchs,
  ) {
    return matchs.where((item) => item.hasMatch(text)).firstOrNull ??
        matchs.first;
  }
}
