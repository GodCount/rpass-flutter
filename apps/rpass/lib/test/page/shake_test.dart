import 'package:flutter/material.dart';
import 'package:rpass/src/widget/shake_widget.dart';

class ShakeTestPage extends StatefulWidget {
  const ShakeTestPage({super.key});

  static const routeName = "/Shake_Test";

  @override
  State<ShakeTestPage> createState() => ShakeTestPageState();
}

class ShakeTestPageState extends State<ShakeTestPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShakeFormField<String>(
                validator: (value) =>
                    value?.isEmpty ?? false ? "no empty" : null,
                builder: (context, validator) {
                  return TextFormField(
                    validator: validator,
                  );
                },
              ),
              ShakeFormField<String>(
                validator: (value) =>
                    value?.isNotEmpty ?? false ? "empty" : null,
                builder: (context, validator) {
                  return TextFormField(
                    validator: validator,
                  );
                },
              ),
              ShakeFormField<String>(
                builder: (context, validator) {
                  return TextFormField(
                    validator: validator,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _formKey.currentState!.validate();
                },
                child: const Text("验证"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
