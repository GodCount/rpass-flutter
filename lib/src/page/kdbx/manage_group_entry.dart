import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../widget/common.dart';

class ManageGroupEntry extends StatefulWidget {
  const ManageGroupEntry({super.key});

  static const routeName = "/manage_group_entry";

  @override
  State<ManageGroupEntry> createState() => _ManageGroupEntryState();
}

class _ManageGroupEntryState extends State<ManageGroupEntry>
    with HintEmptyTextUtil {
  KdbxGroup? _kdbxGroup;

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    _kdbxGroup ??= ModalRoute.of(context)!.settings.arguments as KdbxGroup?;

    if (_kdbxGroup == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("组内密码管理"),
        ),
        body: const Center(
          child: Text("没有找到组！"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("组内密码管理"),
      ),
      body: const Center(
        child: Text("还木有实现!!"),
      ),
    );
  }
}
