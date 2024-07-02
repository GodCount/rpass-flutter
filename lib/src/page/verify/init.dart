import 'package:flutter/material.dart';

import '../../component/component.dart';
import '../../store/verify/contrller.dart';

class InitPassword extends StatefulWidget {
  const InitPassword({super.key, required this.verifyContrller});

  static const routeName = "/init";

  final VerifyController verifyContrller;

  @override
  State<InitPassword> createState() => InitPasswordState();
}

class InitPasswordState extends State<InitPassword> {
  TextEditingController _pwd1Controller = TextEditingController();
  TextEditingController _pwd2Controller = TextEditingController();
  GlobalKey _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const Text(
              "H1 HHHHH",
              style: TextStyle(fontSize: 18),
            ),
            const Text(
                "Lorem qui enim officia elit veniam elit velit sint in."),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _pwd1Controller,
                    decoration: const InputDecoration(
                        labelText: "init password",
                        border: OutlineInputBorder()),
                    validator: (value) {
                      return value == null || value.trim().isEmpty
                          ? "be not empty"
                          : value.length > 3
                              ? null
                              : "must length > 3";
                    },
                  ),
                  TextFormField(
                    controller: _pwd2Controller,
                    decoration: const InputDecoration(
                        labelText: "init password",
                        border: OutlineInputBorder()),
                    validator: (value) {
                      return value == _pwd1Controller.value
                          ? null
                          : "must equal";
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
