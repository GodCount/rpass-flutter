import 'dart:math' as math;

final class CharacterSet {
  const CharacterSet._();

  static final lowerCaseLetters = r"qwertyuiopasdfghjklzxcvbnm";
  static final upperCaseLetters = r"QWERTYUIOPASDFGHJKLZXCVBNM";
  static final numbers = r"0123456789";
  static final symbols =
      r"!@#$%^&*_-=+',./\:;?`|~"
      r'"';
  static final brackets = "()[]{}<>";

  static int probableCharSetLength(String text) {
    List<int> result = [0, 0, 0, 0, 0, 0];

    for (final item in text.split("").toSet()) {
      if (lowerCaseLetters.contains(item)) {
        result[0] = 26;
      } else if (upperCaseLetters.contains(item)) {
        result[1] = 26;
      } else if (numbers.contains(item)) {
        result[2] = 10;
      } else if (symbols.contains(item)) {
        result[3] = 24;
      } else if (brackets.contains(item)) {
        result[4] = 8;
      } else {
        result[5] += 1;
      }
    }

    return result.fold(0, (val, item) => val + item);
  }
}

int randomInt(int min, int max) => min + math.Random().nextInt(max - min);

int passwordEntropy(String password, [String? charSet]) {
  final charSetLength = charSet != null
      ? charSet.length
      : CharacterSet.probableCharSetLength(password);

  if (charSetLength == 0) return 0;

  return (password.length * (math.log(charSetLength) / math.log(2))).round();
}

String randomPassword({
  required int length,
  List<String>? charSet,
  bool eachSetIncludeOne = true,
}) {
  charSet ??= [
    CharacterSet.lowerCaseLetters,
    CharacterSet.upperCaseLetters,
    CharacterSet.numbers,
    CharacterSet.symbols,
    CharacterSet.brackets,
  ];

  final List<String> values = [];
  final List<String> chars = [];

  for (final item in charSet) {
    final list = item.split("")..sort((a, b) => math.Random().nextInt(2));
    if (list.isEmpty) continue;
    if (eachSetIncludeOne) {
      values.add(list[randomInt(0, list.length)]);
    }
    chars.addAll(list);
  }

  if (chars.isEmpty) {
    throw Exception("character set cannot be empty");
  }

  chars.sort((a, b) => math.Random().nextInt(2));

  if (values.length >= length) {
    values.sort((a, b) => math.Random().nextInt(2));
    return values.sublist(0, length).join();
  }

  length -= values.length;
  for (var i = 0; i < length; i++) {
    values.add(chars[randomInt(0, chars.length)]);
  }
  values.sort((a, b) => math.Random().nextInt(2));

  return values.join();
}
