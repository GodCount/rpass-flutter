import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../context/store.dart';
import '../../rpass.dart';
import '../../widget/create_kdbx.dart';
import '../../widget/load_kdbx.dart';
import '../page.dart';

class InitKdbxPage extends StatefulWidget {
  const InitKdbxPage({super.key});

  static const routeName = "/init_kdbx";

  @override
  State<InitKdbxPage> createState() => _InitKdbxPageState();
}

class _InitKdbxPageState extends State<InitKdbxPage> {
  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: store.localInfo.localKdbxFileExists
            ? LoadKdbx(
                readKdbxFile: () async {
                  return (
                    store.localInfo.localKdbxFile.path,
                    await store.localInfo.localKdbxFile.readAsBytes()
                  );
                },
                biometric: true,
                onLoadedKdbx: (kdbx) {
                  KdbxProvider.setKdbx(context, kdbx);
                  Navigator.of(context).pushReplacementNamed(Home.routeName);
                },
              )
            : CreateKdbx(
                kdbxName: RpassInfo.defaultKdbxName,
                onCreatedKdbx: (kdbx) {
                  kdbx.filepath = store.localInfo.localKdbxFile.path;
                  kdbx.save();
                  KdbxProvider.setKdbx(context, kdbx);
                  Navigator.of(context).pushReplacementNamed(Home.routeName);
                },
              ),
      ),
    );
  }
}
