import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:logging/logging.dart';

import '../store/kdbx/controller.dart';
import '../util/cache_network_image.dart';

final _logger = Logger("kdbx:icon");

enum KdbxIconType {
  Key, // : 0,
  World, // : 1,
  Warning, // : 2,
  NetworkServer, // : 3,
  MarkedDirectory, // : 4,
  UserCommunication, // : 5,
  Parts, // : 6,
  Notepad, // : 7,
  WorldSocket, // : 8,
  Identity, // : 9,
  PaperReady, // : 10,
  Digicam, // : 11,
  IRCommunication, // : 12,
  MultiKeys, // : 13,
  Energy, // : 14,
  Scanner, // : 15,
  WorldStar, // : 16,
  CDRom, // : 17,
  Monitor, // : 18,
  EMail, // : 19,
  Configuration, // : 20,
  ClipboardReady, // : 21,
  PaperNew, // : 22,
  Screen, // : 23,
  EnergyCareful, // : 24,
  EMailBox, // : 25,
  Disk, // : 26,
  Drive, // : 27,
  PaperQ, // : 28,
  TerminalEncrypted, // : 29,
  Console, // : 30,
  Printer, // : 31,
  ProgramIcons, // : 32,
  Run, // : 33,
  Settings, // : 34,
  WorldComputer, // : 35,
  Archive, // : 36,
  Homebanking, // : 37,
  DriveWindows, // : 39,
  Clock, // : 39,
  EMailSearch, // : 40,
  PaperFlag, // : 41,
  Memory, // : 42,
  TrashBin, // : 43,
  Note, // : 44,
  Expired, // : 45,
  Info, // : 46,
  Package, // : 47,
  Folder, // : 48,
  FolderOpen, // : 49,
  FolderPackage, // : 50,
  LockOpen, // : 51,
  PaperLocked, // : 52,
  Checked, // : 53,
  Pen, // : 54,
  Thumbnail, // : 55,
  Book, // : 56,
  List, // : 57,
  UserKey, // : 58,
  Tool, // : 59,
  Home, // : 60,
  Star, // : 61,
  Tux, // : 62,
  Feather, // : 63,
  Apple, // : 64,
  Wiki, // : 65,
  Money, // : 66,
  Certificate, // : 67,
  BlackBerry, // : 68
}

extension ToKdbxIcon on KdbxIconType {
  KdbxIcon toKdbxIcon() {
    return KdbxIcon.builtIn(index);
  }
}

class KdbxIcon2Material {
  static const icons = [
    Icons.key_rounded,
    Icons.public_rounded,
    Icons.error_rounded,
    Icons.dns_rounded,
    Icons.push_pin_rounded,
    Icons.forum_rounded,
    Icons.extension_rounded,
    Icons.edit_rounded,
    Icons.power_rounded,
    Icons.perm_identity_rounded,
    Icons.attach_file_rounded,
    Icons.camera_rounded,
    Icons.wifi_rounded,
    Icons.link_rounded,
    Icons.battery_3_bar_rounded,
    Icons.qr_code_rounded,
    Icons.star_rounded,
    Icons.album_rounded,
    Icons.monitor_rounded,
    Icons.email_rounded,
    Icons.toggle_on_rounded,
    Icons.content_paste_rounded,
    Icons.send_rounded,
    Icons.tv_rounded,
    Icons.bolt_rounded,
    Icons.inbox_rounded,
    Icons.save_rounded,
    Icons.storage_rounded,
    Icons.adjust_rounded,
    Icons.enhanced_encryption_rounded,
    Icons.terminal_rounded,
    Icons.print_rounded,
    Icons.terminal_rounded,
    Icons.commit_rounded,
    Icons.settings_rounded,
    Icons.computer_rounded,
    Icons.inventory_2_rounded,
    Icons.credit_card_rounded,
    Icons.laptop_windows_rounded,
    Icons.schedule_rounded,
    Icons.mark_email_unread_rounded,
    Icons.flag_rounded,
    Icons.gamepad_rounded,
    Icons.memory_rounded,
    Icons.sticky_note_2_rounded,
    Icons.event_busy_rounded,
    Icons.info_rounded,
    Icons.view_in_ar_rounded,
    Icons.folder_rounded,
    Icons.folder_open_rounded,
    Icons.leaderboard_rounded,
    Icons.lock_open_rounded,
    Icons.lock_rounded,
    Icons.check_rounded,
    Icons.edit_rounded,
    Icons.account_box_rounded,
    Icons.book_rounded,
    Icons.list_alt_outlined,
    Icons.key_rounded,
    Icons.build_rounded,
    Icons.house_rounded,
    Icons.star_rounded,
    Icons.image_not_supported_rounded,
    Icons.location_pin,
    Icons.apple_rounded,
    Icons.image_not_supported_rounded,
    Icons.paid_rounded,
    Icons.calendar_month_rounded,
    Icons.smartphone_rounded,
  ];

  static IconData? to(int index) {
    if (index < 0 || index >= icons.length) return null;
    return icons[index];
  }
}

class IconConvertBase64 {
  static Future<void> convertByAutofillIcon({
    required AutofillDataset dataset,
    required KdbxController kdbx,
    required bool favicon,
    required Color color,
  }) async {
    if (dataset.data == null) return;

    for (final item in dataset.data!) {
      final id = item["id"];

      final url = item["__icon_url__"];
      final iconBuiltIn = item["__icon_builtin__"] != null
          ? int.tryParse(item["__icon_builtin__"]!) ?? 2
          : 2;
      final iconCustom = item["__icon_custom__"];

      item.remove("__icon_url__");
      item.remove("__icon_builtin__");
      item.remove("__icon_custom__");

      if (id == null) continue;

      if (iconCustom != null) {
        final data = kdbx.fieldSummary?.customIcons[iconCustom];
        if (data != null) {
          dataset.icons[id] = data;
          continue;
        }
      }

      if (favicon && url?.isNotEmpty == true) {
        final data = await CacheNetworkImage.cacheManager.read(url!);
        if (data != null) {
          dataset.icons[id] = data;
          continue;
        }
      }

      final data =
          await _IconDataPngCache.instance.get(
            KdbxIcon2Material.to(iconBuiltIn) ?? KdbxIcon2Material.to(2)!,
            color,
          ) ??
          await _IconDataPngCache.instance.get(KdbxIcon2Material.to(2)!, color);

      if (data != null) {
        dataset.icons[id] = data;
      }
    }
  }
}

class _IconDataPngCache {
  _IconDataPngCache._();
  static final _IconDataPngCache instance = _IconDataPngCache._();

  final double size = 72;

  final Map<String, Uint8List> _cache = {};

  Future<Uint8List?> get(IconData icon, Color color) async {
    final key = _key(icon, color);

    final cached = _cache[key];
    if (cached != null) return Future.value(cached);

    try {
      final data = await _render(icon, color);
      _cache[key] = data;
      return data;
    } catch (e) {
      _logger.warning(e);
      return null;
    }
  }

  String _key(IconData icon, Color color) =>
      '${icon.codePoint}_${icon.fontFamily}_${icon.fontPackage}_'
      '${color.toARGB32()}';

  Future<Uint8List> _render(IconData icon, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final painter = TextPainter(textDirection: .ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      )
      ..layout();
    painter.paint(canvas, Offset.zero);

    final picture = recorder.endRecording();
    final pixel = size.ceil();
    final image = await picture.toImage(pixel, pixel);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    picture.dispose();

    if (data == null) {
      throw StateError('Failed to render icon ${icon.codePoint}');
    }
    return data.buffer.asUint8List();
  }

  void clear() {
    _cache.clear();
  }
}
