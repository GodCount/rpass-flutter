import 'package:flutter/material.dart';

import '../../rpass.dart';
import '../../widget/create_kdbx.dart';

class CreateKdbxPage extends StatefulWidget {
  const CreateKdbxPage({super.key});

  static const routeName = "/create_kdbx";

  @override
  State<CreateKdbxPage> createState() => _CreateKdbxPageState();
}

class _CreateKdbxPageState extends State<CreateKdbxPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: CreateKdbx(
          kdbxName: RpassInfo.defaultKdbxName,
          onCreatedKdbx: (kdbx) {
            Navigator.of(context).pop(kdbx);
          },
        ),
      ),
    );
  }
}
