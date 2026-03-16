import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class Encrypted {
  Encrypted(this.bytes, this.iv);

  final Uint8List iv;
  final Uint8List bytes;
}

class EncryptUtils {
  static Encrypted encryptCBC({
    required Uint8List key,
    Uint8List? iv,
    required Uint8List bytes,
  }) {
    assert(key.length == 32, 'AES-256 requires a 32-byte key');
    assert(iv == null || iv.length == 16, 'AES requires 16 bytes IV');

    iv ??= generatedRandomKey(16);

    final cipher =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()))
          ..init(
            true,
            PaddedBlockCipherParameters(
              ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
              null,
            ),
          );

    return Encrypted(cipher.process(bytes), iv);
  }

  static Uint8List decryptCBC(Uint8List key, Encrypted encrypted) {
    assert(key.length == 32, 'AES-256 requires a 32-byte key');
    assert(encrypted.iv.length == 16, 'AES requires 16 bytes IV');

    final cipher =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()))
          ..init(
            false,
            PaddedBlockCipherParameters(
              ParametersWithIV<KeyParameter>(KeyParameter(key), encrypted.iv),
              null,
            ),
          );

    return cipher.process(encrypted.bytes);
  }

  static Uint8List generatedRandomKey(int length) {
    final Random generator = Random.secure();

    return Uint8List.fromList(
      List.generate(length, (i) => generator.nextInt(256)),
    );
  }
}
