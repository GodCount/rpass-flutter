import 'package:flutter_test/flutter_test.dart';
import 'package:rpass/src/util/random_password.dart';

void main() {
  group("Random Password", () {
    test("length", () {
      expect(randomPassword(length: 0).length, 0);
      expect(randomPassword(length: 4).length, 4);
    });

    test("include cahr", () {
      final password = randomPassword(length: 20).split("");
      expect(password.any((char) => CharacterSet.lowerCaseLetters.contains(char)), isTrue);
      expect(
        password.any((char) => CharacterSet.upperCaseLetters.contains(char)),
        isTrue,
      );
      expect(password.any((char) => CharacterSet.numbers.contains(char)), isTrue);
      expect(password.any((char) => CharacterSet.symbols.contains(char)), isTrue);
      expect(password.any((char) => CharacterSet.brackets.contains(char)), isTrue);
    });

    test("custom cahr", () {
      const customText = "µ∫√ç¬˚∆πø";
      expect(
        randomPassword(
          length: 20,
          charSet: [customText],
        ).split("").every((char) => customText.contains(char)),
        isTrue,
      );
    });

    test("include cahr", () {
      expect(
        randomPassword(
          length: 20,
          charSet: [CharacterSet.lowerCaseLetters],
        ).split("").any((char) => CharacterSet.lowerCaseLetters.contains(char)),
        isTrue,
      );
      expect(
        randomPassword(
          length: 20,
          charSet: [CharacterSet.upperCaseLetters],
        ).split("").any((char) => CharacterSet.upperCaseLetters.contains(char)),
        isTrue,
      );
      expect(
        randomPassword(
          length: 20,
          charSet: [CharacterSet.numbers],
        ).split("").any((char) => CharacterSet.numbers.contains(char)),
        isTrue,
      );
      expect(
        randomPassword(
          length: 20,
          charSet: [CharacterSet.symbols],
        ).split("").any((char) => CharacterSet.symbols.contains(char)),
        isTrue,
      );
      expect(
        randomPassword(
          length: 20,
          charSet: [CharacterSet.brackets],
        ).split("").any((char) => CharacterSet.brackets.contains(char)),
        isTrue,
      );
    });

    test("throw Exception", () {
      expect(
        () => randomPassword(length: 20, charSet: []),
        throwsA(isA<Exception>()),
      );
    });
  });
}
