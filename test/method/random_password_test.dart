import 'package:flutter_test/flutter_test.dart';
import 'package:rpass/src/util/common.dart';

void main() {
  group("Random Password", () {
    test("length", () {
      expect(randomPassword(length: 0).$1.length, 0);
      expect(randomPassword(length: 4).$1.length, 4);
    });

    test("include cahr", () {
      final password = randomPassword(length: 20).$1.split("");
      expect(password.any((char) => letters.contains(char)), isTrue);
      expect(
        password.any((char) => letters.toUpperCase().contains(char)),
        isTrue,
      );
      expect(password.any((char) => numbers.contains(char)), isTrue);
      expect(password.any((char) => symbols.contains(char)), isTrue);
    });

    test("custom cahr", () {
      const customText = "µ∫√ç¬˚∆πø";
      expect(
        randomPassword(
          length: 20,
          customText: customText,
          enableLetterLowercase: false,
          enableLetterUppercase: false,
          enableNumber: false,
          enableSymbol: false,
        ).$1.split("").every((char) => customText.contains(char)),
        isTrue,
      );
    });

    test("not include cahr", () {
      expect(
        randomPassword(length: 20, enableLetterLowercase: false)
            .$1
            .split("")
            .any((char) => letters.contains(char)),
        isFalse,
      );
      expect(
        randomPassword(length: 20, enableLetterUppercase: false)
            .$1
            .split("")
            .any((char) => letters.toUpperCase().contains(char)),
        isFalse,
      );
      expect(
        randomPassword(length: 20, enableNumber: false)
            .$1
            .split("")
            .any((char) => numbers.contains(char)),
        isFalse,
      );
      expect(
        randomPassword(length: 20, enableSymbol: false)
            .$1
            .split("")
            .any((char) => symbols.contains(char)),
        isFalse,
      );
    });

    test("password entropy", () {
      expect(
        randomPassword(length: 20).$2 == randomPassword(length: 20).$2,
        isTrue,
      );

      expect(
        randomPassword(length: 10).$2 == randomPassword(length: 20).$2,
        isFalse,
      );

      expect(
        randomPassword(length: 20, enableLetterLowercase: false).$2 ==
            randomPassword(length: 20).$2,
        isFalse,
      );
    });

    test("throw Exception", () {
      expect(
        () => randomPassword(
          length: 20,
          enableLetterLowercase: false,
          enableLetterUppercase: false,
          enableNumber: false,
          enableSymbol: false,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
