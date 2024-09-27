class KdbxError extends Error {
  KdbxError([this.message]);

  final Object? message;

  @override
  String toString() {
    if (message != null) {
      return "KdbxError failed: ${Error.safeToString(message)}";
    }
    return "KdbxError failed";
  }
}

enum KdbxExceptionCode { NeverLeave_RecycleBin }

class KdbxException implements Exception {
  final dynamic message;
  final KdbxExceptionCode? code;

  KdbxException([this.message, this.code]);

  @override
  String toString() {
    return "KdbxException {code: $code, message: $message}";
  }
}
