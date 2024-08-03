import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  const HighlightText({
    super.key,
    required this.text,
    this.matchText,
    this.prefixText,
    this.style,
    this.matchStyle,
    this.prefixStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.overflow = TextOverflow.clip,
    this.textScaler = TextScaler.noScaling,
    this.maxLines,
  });

  final String text;
  final String? matchText;
  final String? prefixText;

  final TextStyle? style;
  final TextStyle? matchStyle;
  final TextStyle? prefixStyle;

  final TextAlign textAlign;
  final TextDirection? textDirection;
  final TextOverflow overflow;
  final TextScaler textScaler;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? Theme.of(context).textTheme.bodyMedium!;
    final matchStyle = this.matchStyle ??
        style.copyWith(color: Theme.of(context).colorScheme.primary);

    return RichText(
      textAlign: textAlign,
      textDirection: textDirection,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      text: TextSpan(
        text: prefixText,
        style: prefixStyle,
        children: _getMatchTexts(
          style: style,
          matchStyle: matchStyle,
          matchText: matchText ?? '',
        ),
      ),
    );
  }

  List<TextSpan> _getMatchTexts({
    required TextStyle style,
    required TextStyle matchStyle,
    required String matchText,
  }) {
    if (matchText.isEmpty) {
      return [
        TextSpan(
          style: style,
          text: this.text,
        )
      ];
    }

    final List<TextSpan> texts = [];
    final text = this.text.toLowerCase();
    matchText = matchText.toLowerCase();
    final len = matchText.length;

    int position = 0;

    do {
      final index = text.indexOf(matchText, position);
      if (index >= 0) {
        if (index - position > 0) {
          texts.add(TextSpan(
            style: style,
            text: this.text.substring(position, index),
          ));
        }
        position = index + len;
        texts.add(TextSpan(
          style: matchStyle,
          text: this.text.substring(index, position),
        ));
      } else {
        texts.add(TextSpan(
          style: style,
          text: this.text.substring(position),
        ));
        break;
      }
    } while (position < text.length);

    return texts;
  }
}
