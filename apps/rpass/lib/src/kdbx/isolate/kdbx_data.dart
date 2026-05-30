import 'package:kpasslib/kpasslib.dart';

import '../constants.dart';

enum KdbxEntryField { all, passwordPageList }

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

  static final PASSWORD_PAGE_LIST_KEYS = [
    KdbxKeyCommon.TITLE,
    KdbxKeyCommon.URL,
    KdbxKeyCommon.USER_NAME,
    KdbxKeyCommon.EMAIL,
  ];

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

  factory KdbxEntryData.formKdbxEntry(
    KdbxEntry entry, {
    KdbxEntryField type = .all,
  }) {
    return KdbxEntryData(
      uuid: entry.uuid.string,
      times: entry.times,
      icon: entry.icon,
      parent: entry.parent?.uuid.string,
      previousParent: entry.previousParent?.string,
      customIconUuid: entry.customIcon?.string,
      foreground: entry.foreground,
      background: entry.background,
      overrideUrl: entry.overrideUrl,
      qualityCheck: entry.qualityCheck,
      binaries: entry.binaries,
      tags: entry.tags ?? [],
      defaultSequence:
          //  TODO! 应该往上的组搜索
          entry.autoType.defaultSequence ?? defaultAutoTypeSequence,
      fields: switch (type) {
        .all => {...entry.fields},
        .passwordPageList => Map.fromEntries(
          entry.fields.entries.where(
            (item) => PASSWORD_PAGE_LIST_KEYS.contains(item.key),
          ),
        ),
      },
    );
  }
}
