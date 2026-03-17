class AutofillDto {
  AutofillDto({required this.key, required this.fields});

  // 如果存在,则只填充这个
  final String? key;

  final Map<String, String> fields;

  factory AutofillDto.formJson(Map<String, dynamic> map) {
    return AutofillDto(
      key: map["key"] as String?,
      fields: (map["fields"] as Map<String, dynamic>).cast<String, String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {"key": key, "fields": fields};
  }
}
