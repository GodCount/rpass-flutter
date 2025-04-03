abstract class AuthField<T> {
  AuthField({
    required this.key,
    required this.description,
    required this.value,
  });

  final String key;
  final String description;
  T value;

  AuthField<T> clone();
}

class TextAuthField extends AuthField<String> {
  TextAuthField({
    required super.key,
    required super.description,
    required super.value,
  });

  @override
  TextAuthField clone() {
    return TextAuthField(
      key: key,
      description: description,
      value: value,
    );
  }
}

class BoolAuthField extends AuthField<bool> {
  BoolAuthField({
    required super.key,
    required super.description,
    required super.value,
  });

  @override
  BoolAuthField clone() {
    return BoolAuthField(
      key: key,
      description: description,
      value: value,
    );
  }
}

class NumberAuthField extends AuthField<int> {
  NumberAuthField({
    required super.key,
    required super.description,
    required super.value,
    this.min,
    this.max,
  });

  final int? min;
  final int? max;

  @override
  NumberAuthField clone() {
    return NumberAuthField(
      key: key,
      description: description,
      value: value,
      min: min,
      max: max,
    );
  }
}

class PasswordAuthField extends AuthField<String> {
  PasswordAuthField({
    required super.key,
    required super.description,
    required super.value,
  });

  @override
  PasswordAuthField clone() {
    return PasswordAuthField(
      key: key,
      description: description,
      value: value,
    );
  }
}

class OptionAuthField extends AuthField<String> {
  OptionAuthField({
    required super.key,
    required super.description,
    required super.value,
    required List<String> optionList,
  }) : optionList = List.from(optionList, growable: false);

  final List<String> optionList;

  @override
  OptionAuthField clone() {
    return OptionAuthField(
      key: key,
      description: description,
      value: value,
      optionList: List.from(optionList, growable: false),
    );
  }
}

T getField<T extends AuthField>(Map<String, AuthField> formData, String key) {
  assert(formData[key] != null, "$key filed is null");
  assert(formData[key] is T, "$key type not is $T");
  return formData[key] as T;
}

abstract class RemoteClientConfig {}
