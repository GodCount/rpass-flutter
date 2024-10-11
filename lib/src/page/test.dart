import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../old/model/rpass/account.dart';

const testData =
    "Esse ad Lorem elit cupidatat duis culpa irure in.Lorem laboris nostrud fugiat ut enim eiusmod voluptate. Sunt fugiat commodo consequat velit nostrud exercitation proident. Sint commodo id elit labore laborum excepteur elit velit enim laboris sint enim non ad."
    "Velit sint commodo sunt commodo non laboris non anim nostrud amet. Cillum ex nisi anim incididunt ullamco qui eu ex fugiat minim. Ea commodo laboris fugiat aute. Dolor tempor adipisicing labore qui eiusmod. Proident esse quis esse dolor elit. Cillum tempor occaecat cupidatat ipsum ex. Laboris sint dolore ex velit occaecat reprehenderit non nisi anim."
    "Qui proident officia aliqua ullamco eu ex elit duis qui laborum. Ex nostrud officia commodo ad proident veniam excepteur nulla dolor. Est reprehenderit id occaecat deserunt pariatur qui minim voluptate. Laborum veniam minim tempor labore aute consectetur. Culpa esse commodo pariatur aute est enim ex dolore et."
    "Nostrud proident tempor duis ex sunt dolore ad non adipisicing fugiat sint adipisicing sunt. Do ad dolor proident incididunt pariatur deserunt exercitation ipsum laboris cillum minim ex. Sint ut dolore nostrud velit velit veniam aliquip do labore. Exercitation cupidatat adipisicing voluptate quis sunt magna pariatur."
    "Anim incididunt ea aute tempor labore amet est laborum nulla labore. Reprehenderit non est non dolore esse exercitation ex cupidatat non officia tempor. Deserunt pariatur irure ut nostrud amet Lorem eiusmod ullamco occaecat sit aliquip adipisicing. Culpa cillum veniam non deserunt dolor aute. Ad cillum nostrud do incididunt laboris laborum officia amet ut ex. Id aute tempor labore cillum est sint enim dolore non magna amet."
    "Do nostrud incididunt minim dolor esse do. Nulla voluptate minim ex id reprehenderit labore commodo occaecat esse exercitation laborum ullamco exercitation sunt. Est dolor cillum culpa eiusmod ad excepteur. Nostrud cillum adipisicing labore qui esse proident aute incididunt excepteur aliquip non. In labore nulla nulla elit nostrud sit occaecat veniam veniam. Mollit quis aute ipsum id commodo ullamco est sit nisi sit esse cupidatat nostrud incididunt. Consectetur labore ut minim irure."
    "Est culpa enim laborum dolore laborum adipisicing eiusmod dolor. Fugiat cupidatat non dolore occaecat reprehenderit sit cillum laboris. Incididunt incididunt elit duis commodo officia aute mollit."
    "Proident incididunt aute irure ex exercitation exercitation ipsum. Veniam quis quis ad aliquip commodo eu tempor tempor ad ullamco irure adipisicing ex tempor. Cillum incididunt pariatur mollit cupidatat reprehenderit. Tempor qui cillum nisi esse qui non. Nostrud officia aliqua eu aliqua proident velit consequat do Lorem dolore ea pariatur officia proident. Excepteur consequat do et culpa aute amet ex ut tempor aute cupidatat nulla Lorem do."
    "Deserunt nulla laborum reprehenderit non voluptate nulla cupidatat qui. Voluptate culpa est laboris ad ipsum. Officia in reprehenderit nisi laboris reprehenderit."
    "Labore anim nostrud et pariatur nostrud esse eu cupidatat laboris reprehenderit anim elit ea. Incididunt excepteur aliqua incididunt ad fugiat proident culpa incididunt eiusmod laboris pariatur tempor. Labore proident incididunt mollit esse. Id commodo cupidatat ea ullamco commodo adipisicing commodo amet pariatur cupidatat ea.";

int next(int min, int max) {
  int res = min + math.Random().nextInt(max - min);
  return res;
}

String getRandomData(int length) {
  final int start = next(0, testData.length - length - 1);
  return testData.substring(start, start + length);
}

List<Account> generateTestData(int start, int end) {
  final List<Account> list = [];
  for (int i = start; i < end; i++) {
    list.add(
      Account(
        account: "$i" * 5,
        domainName: "$i" * 5,
        domain: "$i" * 5,
        email: "$i" * 5,
        password: "$i" * 5,
        description: "$i" * 5,
      ),
    );
  }
  return list;
}
