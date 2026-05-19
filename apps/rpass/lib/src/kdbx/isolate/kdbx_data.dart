import 'package:kpasslib/kpasslib.dart';

class KdbxGroupData {
  KdbxGroupData({
    required this.uuid,
    required this.times,
    required this.icon,
    required this.customIconUuid,
    required this.parent,
    required this.previousParent,
    required this.name,
    required this.notes,
    required this.isExpanded,
    required this.isSearchingEnabled,
    required this.isAutoTypeEnabled,
    required this.defaultAutoTypeSeq,
  });

  final String uuid;

  final KdbxTimes times;

  final KdbxIcon icon;

  final String? customIconUuid;

  final String? parent;

  final String? previousParent;

  final String name;

  final String notes;

  final bool? isExpanded;

  final bool? isSearchingEnabled;

  final bool? isAutoTypeEnabled;

  final String? defaultAutoTypeSeq;
}

class KdbxEntryData {
  KdbxEntryData({
    required this.uuid,
    required this.times,
    required this.icon,
    this.parent,
    this.previousParent,
    this.customIconUuid,
    this.foreground,
    this.background,
    this.overrideUrl,
    this.qualityCheck,
    required this.binaries,
    required this.tags,
    required this.defaultSequence,
    required this.fields,
  });

  final String uuid;

  final KdbxTimes times;

  final KdbxIcon icon;

  final String? customIconUuid;

  final String? parent;

  final String? previousParent;

  final String? foreground;

  final String? background;

  final String? overrideUrl;

  final bool? qualityCheck;

  final Map<String, BinaryReference> binaries;

  final List<String> tags;

  final String defaultSequence;

  final Map<String, KdbxTextField> fields;
}
