import 'package:common_native_channel/common_native_channel.dart';
import 'package:flutter/material.dart';

class PrevFocusWindowPage extends StatefulWidget {
  const PrevFocusWindowPage({super.key});

  @override
  State<PrevFocusWindowPage> createState() => _PrevFocusWindowPageState();
}

class _PrevFocusWindowPageState extends State<PrevFocusWindowPage> with PrevFocusWindowListener {
  @override
  void initState() {
    super.initState();
    prevFocusWindow.addListener(this);
  }

  @override
  void onWindowChange(String? name) {
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    prevFocusWindow.removeListener(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin example app')),
      body: Center(
        child: Column(
          children: [
            Text(
              'Previous Focus Windows Title: ${prevFocusWindow.targetWindowName}\n',
            ),
            TextButton(
              onPressed: prevFocusWindow.targetWindowName != null
                  ? () {
                      prevFocusWindow.activatePrevWindow();
                    }
                  : null,
              child: Text("Activate Previous Window"),
            ),
          ],
        ),
      ),
    );
  }
}
