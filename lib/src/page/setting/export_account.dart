import 'package:flutter/material.dart';

import '../../store/index.dart';

class ExportAccountPage extends StatefulWidget {
  const ExportAccountPage({super.key, required this.store});

  static const routeName = "/export_account";

  final Store store;

  @override
  ExportAccountPageState createState() => ExportAccountPageState();
}

class ExportAccountPageState extends State<ExportAccountPage> {
  bool isEncrypt = true;
  String passwordType = "current";
  bool isCurrentSecurityQuestion = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("导出"),
        centerTitle: true,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                children: [
                  SwitchListTile(
                    value: isEncrypt,
                    onChanged: (value) {
                      setState(() {
                        isEncrypt = value;
                      });
                    },
                    title: const Text("加密"),
                  ),
                  Row(
                    children: [
                      RadioListTile<String>(
                        value: passwordType,
                        groupValue: "current",
                        onChanged: (value) {
                          setState(() {
                            passwordType = value!;
                          });
                        },
                        title: const Text("当前"),
                      ),
                      RadioListTile<String>(
                        value: passwordType,
                        groupValue: "new",
                        onChanged: (value) {
                          setState(() {
                            passwordType = value!;
                          });
                        },
                        title: const Text("独立"),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
