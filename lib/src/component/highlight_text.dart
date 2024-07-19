import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  const HighlightText({
    super.key,
    required this.text,
    this.matchText,
    this.style,
    this.matchStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.overflow = TextOverflow.clip,
    this.textScaler = TextScaler.noScaling,
    this.maxLines,
  });

  final String text;
  final String? matchText;

  final TextStyle? style;
  final TextStyle? matchStyle;

  final TextAlign textAlign;
  final TextDirection? textDirection;
  final TextOverflow overflow;
  final TextScaler textScaler;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? Theme.of(context).textTheme.bodyMedium!;
    final matchStyle = this.matchStyle ??
        style.copyWith(color: Theme.of(context).primaryColor);

    if (matchText == null || matchText!.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
      );
    }

    return RichText(
      textAlign: textAlign,
      textDirection: textDirection,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      text: TextSpan(
        style: style,
        children: _getMatchTexts(
          matchStyle: matchStyle,
          matchText: matchText!,
        ),
      ),
    );
  }

  List<TextSpan> _getMatchTexts({
    required TextStyle matchStyle,
    required String matchText,
  }) {
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
            text: text.substring(position, index),
          ));
        }
        position = index + len;
        texts.add(TextSpan(
          text: text.substring(index, position),
          style: matchStyle,
        ));
      } else {
        texts.add(TextSpan(
          text: text.substring(position),
        ));
        break;
      }
    } while (position < text.length);

    return texts;
  }
}
