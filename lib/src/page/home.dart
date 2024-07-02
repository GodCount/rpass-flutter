import 'package:flutter/material.dart';


import '../page/page.dart';
import '../store/index.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.store});

  static const routeName = "/";

  final Store store;

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
            onPressed: () {
              Navigator.of(context)
                  .pushReplacementNamed(InitPassword.routeName);
            },
            child: const Text("to init password")),
      ),
    );
  }
}
