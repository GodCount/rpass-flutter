import 'package:flutter/material.dart';

// import '../../component/component.dart';
import '../../store/verify/contrller.dart';

class InitPassword extends StatefulWidget {
  const InitPassword({super.key, required this.verifyContrller});

  static const routeName = "/init";

  final VerifyController verifyContrller;

  @override
  State<InitPassword> createState() => InitPasswordState();
}

class InitPasswordState extends State<InitPassword> {
  final TextEditingController _pwd1Controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "H1 HHHHH",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
                "Lorem qui enim officia elit veniam elit velit sint in."),
            const SizedBox(
              height: 24,
            ),
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _pwd1Controller,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
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
                    const SizedBox(
                      height: 12,
                    ),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                          labelText: "confirm init password",
                          border: OutlineInputBorder()),
                      validator: (value) {
                        return value == _pwd1Controller.value.text
                            ? null
                            : "must equal";
                      },
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    IconButton.filledTonal(
                        onPressed: () {
                          // _formKey.currentState?.validate();
                        },
                        iconSize: 48,
                        icon: const Icon(Icons.keyboard_arrow_right_rounded))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
