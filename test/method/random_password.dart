import 'package:flutter_test/flutter_test.dart';
import 'package:rpass/src/util/common.dart';

void main() {
  group("Random Password", () {
    test("length", () {
      expect(randomPassword(length: 0).length, 0);
      expect(randomPassword(length: 4).length, 4);
    });

    test("include cahr", () {
      final password = randomPassword(length: 20).split("");
      expect(password.any((char) => letters.contains(char)), isTrue);
      expect(
          password.any((char) => letters.toUpperCase().contains(char)), isTrue);
      expect(password.any((char) => numbers.contains(char)), isTrue);
      expect(password.any((char) => symbols.contains(char)), isTrue);
    });

    test("not include cahr", () {
      expect(
        randomPassword(length: 20, enableLetterLowercase: false)
            .split("")
            .any((char) => letters.contains(char)),
        isFalse,
      );
      expect(
        randomPassword(length: 20, enableLetterUppercase: false)
            .split("")
            .any((char) => letters.toUpperCase().contains(char)),
        isFalse,
      );
      expect(
        randomPassword(length: 20, enableNumber: false)
            .split("")
            .any((char) => numbers.contains(char)),
        isFalse,
      );
      expect(
        randomPassword(length: 20, enableSymbol: false)
            .split("")
            .any((char) => symbols.contains(char)),
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
