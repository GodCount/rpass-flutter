import 'package:flutter/material.dart';
import 'package:prev_focus_window/prev_focus_window.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with PrevFocusWindowListener {
  @override
  void initState() {
    super.initState();
    PrevFocusWindow.instance.addListener(this);
  }

  @override
  void onWindowChange(String? name) {
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    PrevFocusWindow.instance.removeListener(this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            children: [
              Text(
                'Previous Focus Windows Title: ${PrevFocusWindow.instance.targetWindowName}\n',
              ),
              TextButton(
                onPressed: PrevFocusWindow.instance.targetWindowName != null
                    ? () {
                        PrevFocusWindow.instance.activatePrevWindow();
                      }
                    : null,
                child: Text("Activate Previous Window"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
