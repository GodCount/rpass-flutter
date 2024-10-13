import 'package:flutter/material.dart';

import '../../context/store.dart';
import '../../widget/common.dart';

class KdbxSettingPage extends StatefulWidget {
  const KdbxSettingPage({super.key});

  static const routeName = "/kdbx_setting";

  @override
  State<KdbxSettingPage> createState() => _KdbxSettingPageState();
}

class _KdbxSettingPageState extends State<KdbxSettingPage>
    with CommonWidgetUtil {
  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);

    return Scaffold(resizeToAvoidBottomInset: false, body: Center());
  }
}
