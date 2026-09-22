import 'dart:convert';
import 'dart:typed_data';

import 'package:lan_fill_server/lan_fill_server.dart';
import 'package:lan_fill_server/src/util/common.dart';
import 'package:lan_fill_server/src/util/constant.dart';
import 'package:lan_fill_server/src/util/encrypt_utils.dart';
import 'package:test/test.dart';

void main() {
  group('isDesktopPlatform', () {
    test('recognizes desktop platforms', () {
      expect(isDesktopPlatform('linux'), isTrue);
      expect(isDesktopPlatform('macos'), isTrue);
      expect(isDesktopPlatform('windows'), isTrue);
    });

    test('rejects non-desktop platforms', () {
      expect(isDesktopPlatform('android'), isFalse);
      expect(isDesktopPlatform('ios'), isFalse);
      expect(isDesktopPlatform('web'), isFalse);
      expect(isDesktopPlatform(''), isFalse);
      expect(isDesktopPlatform('Windows'), isFalse);
    });
  });

  group('HeadersConstant', () {
    test('header names are stable', () {
      expect(HeadersConstant.deviceName, 'r-device-name');
      expect(HeadersConstant.deviceAppVersion, 'r-app-version');
      expect(HeadersConstant.aesIv, 'r-aes-iv');
      expect(HeadersConstant.deviceFingerprint, 'r-device-fingerprint');
      expect(HeadersConstant.devicePlatform, 'r-device-platform');
      expect(HeadersConstant.filename, 'r-file-name');
    });
  });

  group('AutofillDto', () {
    test('round-trips json with key', () {
      final dto = AutofillDto(
        key: 'password',
        fields: {'username': 'alice', 'password': 'secret', 'otp': null},
      );

      final restored = AutofillDto.formJson(dto.toJson());

      expect(restored.key, 'password');
      expect(restored.fields, {
        'username': 'alice',
        'password': 'secret',
        'otp': null,
      });
    });

    test('round-trips json without key', () {
      final json = {
        'key': null,
        'fields': {'title': 'example'},
      };

      final dto = AutofillDto.formJson(json);

      expect(dto.key, isNull);
      expect(dto.fields, {'title': 'example'});
      expect(dto.toJson(), json);
    });
  });

  group('RegisterDto', () {
    test('round-trips json', () {
      final dto = RegisterDto(
        addres: ['192.168.1.10', '10.0.0.2'],
        port: 8443,
        code: 'ABCDEFGH',
      );

      final restored = RegisterDto.formJson(dto.toJson());

      expect(restored.addres, ['192.168.1.10', '10.0.0.2']);
      expect(restored.port, 8443);
      expect(restored.code, 'ABCDEFGH');
    });
  });

  group('DeviceInfoDto', () {
    test('stores provided fields', () {
      final info = DeviceInfoDto(
        deviceName: 'Pixel',
        appVersion: '1.2.3',
        fingerprint: 'abc123',
      );

      expect(info.deviceName, 'Pixel');
      expect(info.appVersion, '1.2.3');
      expect(info.fingerprint, 'abc123');
    });
  });

  group('EncryptUtils', () {
    test('generatedRandomKey returns requested length', () {
      final key = EncryptUtils.generatedRandomKey(32);

      expect(key, hasLength(32));
      expect(key, isA<Uint8List>());
    });

    test('encryptCBC / decryptCBC round-trip', () {
      final key = EncryptUtils.generatedRandomKey(32);
      final plaintext = utf8.encode('hello lan fill');

      final encrypted = EncryptUtils.encryptCBC(key: key, bytes: plaintext);
      final decrypted = EncryptUtils.decryptCBC(key, encrypted);

      expect(encrypted.iv, hasLength(16));
      expect(encrypted.bytes, isNot(equals(plaintext)));
      expect(utf8.decode(decrypted), 'hello lan fill');
    });

    test('encryptCBC uses provided iv', () {
      final key = EncryptUtils.generatedRandomKey(32);
      final iv = EncryptUtils.generatedRandomKey(16);
      final plaintext = utf8.encode('same iv');

      final encrypted = EncryptUtils.encryptCBC(
        key: key,
        iv: iv,
        bytes: plaintext,
      );

      expect(encrypted.iv, iv);
      expect(utf8.decode(EncryptUtils.decryptCBC(key, encrypted)), 'same iv');
    });

    test('same key and iv produce deterministic ciphertext', () {
      final key = EncryptUtils.generatedRandomKey(32);
      final iv = EncryptUtils.generatedRandomKey(16);
      final plaintext = utf8.encode('deterministic');

      final a = EncryptUtils.encryptCBC(key: key, iv: iv, bytes: plaintext);
      final b = EncryptUtils.encryptCBC(key: key, iv: iv, bytes: plaintext);

      expect(a.bytes, b.bytes);
    });
  });

  group('StoredSecurityContext', () {
    test('round-trips json', () {
      final context = StoredSecurityContext(
        privateKey: 'private',
        publicKey: 'public',
        certificate: 'cert',
        certificateHash: 'hash',
      );

      final restored = StoredSecurityContext.formJson(context.toJson());

      expect(restored.privateKey, 'private');
      expect(restored.publicKey, 'public');
      expect(restored.certificate, 'cert');
      expect(restored.certificateHash, 'hash');
      expect(restored.certificateBytes, utf8.encode('cert'));
      expect(restored.privateKeyBytes, utf8.encode('private'));
    });
  });

  group('generateSecurityContext', () {
    test('produces usable pem material and matching hash', () {
      final context = generateSecurityContext();

      expect(context.privateKey, contains('BEGIN RSA PRIVATE KEY'));
      expect(context.publicKey, contains('BEGIN RSA PUBLIC KEY'));
      expect(context.certificate, contains('BEGIN CERTIFICATE'));
      expect(context.certificateHash, isNotEmpty);
      expect(
        calculateHashOfCertificate(context.certificate),
        context.certificateHash,
      );
    });

    test('calculateHashOfCertificate is stable for same pem', () {
      final context = generateSecurityContext();
      final hash1 = calculateHashOfCertificate(context.certificate);
      final hash2 = calculateHashOfCertificate(context.certificate);

      expect(hash1, hash2);
      expect(hash1, context.certificateHash);
    });
  });

  group('EncryptCertificateTotp', () {
    test('codeString length matches codeLength', () {
      final totp = EncryptCertificateTotp(
        codeLength: 10,
        interval: const Duration(seconds: 60),
      );

      expect(totp.codeString(), hasLength(10));
      expect(totp.codeBytes(), utf8.encode(totp.codeString()));
    });

    test('code and codeString stay aligned within the same second', () {
      final totp = EncryptCertificateTotp(codeLength: 8);
      final stringCode = totp.codeString();
      final intCode = totp.code();

      expect(int.parse(stringCode), intCode);
    });

    test('nextInterval is within configured interval', () {
      final totp = EncryptCertificateTotp(
        interval: const Duration(seconds: 30),
      );

      final remaining = totp.nextInterval();

      expect(remaining.inSeconds, greaterThanOrEqualTo(0));
      expect(remaining.inSeconds, lessThanOrEqualTo(30));
    });
  });

  group('LanFillServerOption / LanFillCilentOption', () {
    test('server option keeps defaults', () {
      final security = generateSecurityContext();
      final option = LanFillServerOption(
        deviceInfo: DeviceInfoDto(
          deviceName: 'mac',
          appVersion: '1.0.0',
          fingerprint: 'fp',
        ),
        securityContext: security,
      );

      expect(option.idleCloseTimeout, const Duration(minutes: 5));
      expect(option.secretKeyInterval, const Duration(seconds: 60));
    });

    test('client option keeps defaults', () {
      final option = LanFillCilentOption(
        deviceInfo: DeviceInfoDto(
          deviceName: 'phone',
          appVersion: '2.0.0',
          fingerprint: 'fp2',
        ),
      );

      expect(option.heartbeatDuration, const Duration(minutes: 2));
    });
  });
}
