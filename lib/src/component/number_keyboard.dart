import 'package:flutter/material.dart';

typedef InputCallback = void Function(String number);

// ignore: constant_identifier_names
const DELETE_KEY = "-";

const List<String> keyboardList = [
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "",
  "0",
  DELETE_KEY
];

class NumberKeyboard extends StatelessWidget {
  const NumberKeyboard({super.key, required this.inputCallback});

  final InputCallback inputCallback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _createRowNumberKey(keyboardList.sublist(0, 3)),
          _createRowNumberKey(keyboardList.sublist(3, 6)),
          _createRowNumberKey(keyboardList.sublist(6, 9)),
          _createRowNumberKey(keyboardList.sublist(9)),
        ],
      ),
    );
  }

  Widget _createRowNumberKey(List<String> list) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: list.map((value) {
        return NumberKey(
          key: super.key,
          value: value,
          callKey: (value) => {inputCallback(value)},
        );
      }).toList(),
    );
  }

}

class NumberKey extends StatelessWidget {
  const NumberKey({super.key, required this.value, required this.callKey});

  final String value;
  final InputCallback callKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.all(4),
      width: MediaQuery.of(context).size.width / 3 - 56,
      alignment: Alignment.center,
      child: _createKey(),
    );
  }

  Widget _createKey() {
    if (value == DELETE_KEY) {
      return TextButton.icon(
          onPressed: () {
            callKey(value);
          },
          icon: const Icon(Icons.backspace),
          iconAlignment: IconAlignment.end,
          label: const Text(""));
    } else if (value.isEmpty) {
      return const Text("");
    } else {
      return TextButton(
          onPressed: () {
            callKey(value);
          },
          child: Text(value));
    }
  }
}
