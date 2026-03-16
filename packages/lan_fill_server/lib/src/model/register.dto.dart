class RegisterDto {
  RegisterDto({required this.addres, required this.port, required this.code});

  final List<String> addres;

  final int port;

  final String code;

  factory RegisterDto.formJson(Map<String, dynamic> map) {
    return RegisterDto(
      addres: (map["addres"] as List<dynamic>).cast<String>(),
      port: map["port"] as int,
      code: map["code"] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {"addres": addres, "port": port, "code": code};
  }
}
