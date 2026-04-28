import 'package:flutter_test/flutter_test.dart';
import 'package:rpass/src/util/common.dart';

void main() {
  group("transformStorageUnit", () {
    test("B to B (same unit)", () {
      expect(transformStorageUnit(1024, StorageUnit.B, StorageUnit.B), 1024);
    });

    test("B to KB", () {
      expect(transformStorageUnit(1024, StorageUnit.B, StorageUnit.KB), 1);
    });

    test("B to MB", () {
      expect(transformStorageUnit(1024 * 1024, StorageUnit.B, StorageUnit.MB), 1);
    });

    test("KB to B", () {
      expect(transformStorageUnit(1, StorageUnit.KB, StorageUnit.B), 1024);
    });

    test("MB to KB", () {
      expect(transformStorageUnit(1, StorageUnit.MB, StorageUnit.KB), 1024);
    });

    test("GB to MB", () {
      expect(transformStorageUnit(1, StorageUnit.GB, StorageUnit.MB), 1024);
    });

    test("decimal values", () {
      expect(
        transformStorageUnit(2048, StorageUnit.B, StorageUnit.KB),
        2,
      );
    });

    test("with double input", () {
      expect(
        transformStorageUnit(1536.0, StorageUnit.B, StorageUnit.KB),
        1.5,
      );
    });

    test("zero bytes", () {
      expect(transformStorageUnit(0, StorageUnit.B, StorageUnit.KB), 0);
    });

    test("TB to B", () {
      expect(
        transformStorageUnit(1, StorageUnit.TB, StorageUnit.B),
        1024 * 1024 * 1024 * 1024,
      );
    });
  });
}
