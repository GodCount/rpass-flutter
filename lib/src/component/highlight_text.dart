import 'package:flutter/material.dart';

import 'match_text.dart';

class HighlightText extends MatchText {
  HighlightText({
    super.key,
    this.matchText,
    this.prefixText,
    this.matchStyle,
    this.prefixStyle,
    required super.text,
    super.style,
    super.textAlign,
    super.textDirection,
    super.overflow,
    super.textScaler,
    super.maxLines,
  }) : super(matchs: []);

  final String? matchText;
  final String? prefixText;

  final TextStyle? matchStyle;
  final TextStyle? prefixStyle;

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? Theme.of(context).textTheme.bodyMedium!;
    final matchStyle = this.matchStyle ??
        style.copyWith(color: Theme.of(context).colorScheme.primary);

    List<MatchHighlight>? matchs;
    if (matchText != null && matchText!.isNotEmpty) {
      matchs = [
        MatchHighlight(
          regExp: RegExp(RegExp.escape(matchText!), caseSensitive: false),
          style: matchStyle,
        )
      ];
    }

    return RichText(
      textAlign: textAlign,
      textDirection: textDirection,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      text: TextSpan(
        style: style,
        children: matchTexts(matchs: matchs, style: style)
          ..insert(
            0,
            TextSpan(
              text: prefixText,
              style: prefixStyle,
            ),
          ),
      ),
    );
  }
}
