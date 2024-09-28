import 'package:flutter/material.dart';

import '../../widget/load_kdbx.dart';

class LoadKdbxPageArguments {
  LoadKdbxPageArguments({
    required this.readKdbxFile,
    this.biometric = false,
  });

  final ReadKdbxFile readKdbxFile;

  final bool biometric;
}

class LoadKdbxPage extends StatefulWidget {
  const LoadKdbxPage({
    super.key,
  });

  static const routeName = "/load_kdbx";

  @override
  State<LoadKdbxPage> createState() => _LoadKdbxPageState();
}

class _LoadKdbxPageState extends State<LoadKdbxPage> {
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as LoadKdbxPageArguments;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: LoadKdbx(
          readKdbxFile: args.readKdbxFile,
          biometric: args.biometric,
          onLoadedKdbx: (kdbx) {
            Navigator.of(context).pop(kdbx);
          },
        ),
      ),
    );
  }
}
