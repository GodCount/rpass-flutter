// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../model/account.dart';

const String _loremIpsumParagraph =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
    'tempor incididunt ut labore et dolore magna aliqua. Vulputate dignissim '
    'suspendisse in est. Ut ornare lectus sit amet. Eget nunc lobortis mattis '
    'aliquam faucibus purus in. Hendrerit gravida rutrum quisque non tellus '
    'orci ac auctor. Mattis aliquam faucibus purus in massa. Tellus rutrum '
    'tellus pellentesque eu tincidunt tortor. Nunc eget lorem dolor sed. Nulla '
    'at volutpat diam ut venenatis tellus in metus. Tellus cras adipiscing enim '
    'eu turpis. Pretium fusce id velit ut tortor. Adipiscing enim eu turpis '
    'egestas pretium. Quis varius quam quisque id. Blandit aliquam etiam erat '
    'velit scelerisque. In nisl nisi scelerisque eu. Semper risus in hendrerit '
    'gravida rutrum quisque. Suspendisse in est ante in nibh mauris cursus '
    'mattis molestie. Adipiscing elit duis tristique sollicitudin nibh sit '
    'amet commodo nulla. Pretium viverra suspendisse potenti nullam ac tortor '
    'vitae.\n'
    '\n'
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
    'tempor incididunt ut labore et dolore magna aliqua. Vulputate dignissim '
    'suspendisse in est. Ut ornare lectus sit amet. Eget nunc lobortis mattis '
    'aliquam faucibus purus in. Hendrerit gravida rutrum quisque non tellus '
    'orci ac auctor. Mattis aliquam faucibus purus in massa. Tellus rutrum '
    'tellus pellentesque eu tincidunt tortor. Nunc eget lorem dolor sed. Nulla '
    'at volutpat diam ut venenatis tellus in metus. Tellus cras adipiscing enim '
    'eu turpis. Pretium fusce id velit ut tortor. Adipiscing enim eu turpis '
    'egestas pretium. Quis varius quam quisque id. Blandit aliquam etiam erat '
    'velit scelerisque. In nisl nisi scelerisque eu. Semper risus in hendrerit '
    'gravida rutrum quisque. Suspendisse in est ante in nibh mauris cursus '
    'mattis molestie. Adipiscing elit duis tristique sollicitudin nibh sit '
    'amet commodo nulla. Pretium viverra suspendisse potenti nullam ac tortor '
    'vitae';

const double _fabDimension = 56.0;

/// The demo page for [OpenContainerTransform].
class OpenContainerTransformDemo extends StatefulWidget {
  /// Creates the demo page for [OpenContainerTransform].
  const OpenContainerTransformDemo({super.key});

  @override
  State<OpenContainerTransformDemo> createState() {
    return _OpenContainerTransformDemoState();
  }
}

class _OpenContainerTransformDemoState
    extends State<OpenContainerTransformDemo> {
  ContainerTransitionType _transitionType = ContainerTransitionType.fade;

  void _showMarkedAsDoneSnackbar(bool? isMarkedAsDone) {
    if (isMarkedAsDone ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Marked as done!'),
      ));
    }
  }

  void _showSettingsBottomModalSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: 125,
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Fade mode',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  ToggleButtons(
                    borderRadius: BorderRadius.circular(2.0),
                    selectedBorderColor: Theme.of(context).colorScheme.primary,
                    onPressed: (int index) {
                      setModalState(() {
                        setState(() {
                          _transitionType = index == 0
                              ? ContainerTransitionType.fade
                              : ContainerTransitionType.fadeThrough;
                        });
                      });
                    },
                    isSelected: <bool>[
                      _transitionType == ContainerTransitionType.fade,
                      _transitionType == ContainerTransitionType.fadeThrough,
                    ],
                    children: const <Widget>[
                      Text('FADE'),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text('FADE THROUGH'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print("build test page");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Container transform'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsBottomModalSheet(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          _OpenContainerWrapper(
            transitionType: _transitionType,
            closedBuilder: (BuildContext _, VoidCallback openContainer) {
              return _ExampleCard(openContainer: openContainer);
            },
            onClosed: _showMarkedAsDoneSnackbar,
          ),
          const SizedBox(height: 16.0),
          _OpenContainerWrapper(
            transitionType: _transitionType,
            closedBuilder: (BuildContext _, VoidCallback openContainer) {
              return _ExampleSingleTile(openContainer: openContainer);
            },
            onClosed: _showMarkedAsDoneSnackbar,
          ),
          const SizedBox(height: 16.0),
          Row(
            children: <Widget>[
              Expanded(
                child: _OpenContainerWrapper(
                  transitionType: _transitionType,
                  closedBuilder: (BuildContext _, VoidCallback openContainer) {
                    return _SmallerCard(
                      openContainer: openContainer,
                      subtitle: 'Secondary text',
                    );
                  },
                  onClosed: _showMarkedAsDoneSnackbar,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _OpenContainerWrapper(
                  transitionType: _transitionType,
                  closedBuilder: (BuildContext _, VoidCallback openContainer) {
                    return _SmallerCard(
                      openContainer: openContainer,
                      subtitle: 'Secondary text',
                    );
                  },
                  onClosed: _showMarkedAsDoneSnackbar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: <Widget>[
              Expanded(
                child: _OpenContainerWrapper(
                  transitionType: _transitionType,
                  closedBuilder: (BuildContext _, VoidCallback openContainer) {
                    return _SmallerCard(
                      openContainer: openContainer,
                      subtitle: 'Secondary',
                    );
                  },
                  onClosed: _showMarkedAsDoneSnackbar,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _OpenContainerWrapper(
                  transitionType: _transitionType,
                  closedBuilder: (BuildContext _, VoidCallback openContainer) {
                    return _SmallerCard(
                      openContainer: openContainer,
                      subtitle: 'Secondary',
                    );
                  },
                  onClosed: _showMarkedAsDoneSnackbar,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _OpenContainerWrapper(
                  transitionType: _transitionType,
                  closedBuilder: (BuildContext _, VoidCallback openContainer) {
                    return _SmallerCard(
                      openContainer: openContainer,
                      subtitle: 'Secondary',
                    );
                  },
                  onClosed: _showMarkedAsDoneSnackbar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          ...List<Widget>.generate(10, (int index) {
            return OpenContainer<bool>(
              transitionType: _transitionType,
              openBuilder: (BuildContext _, VoidCallback openContainer) {
                return const _DetailsPage();
              },
              onClosed: _showMarkedAsDoneSnackbar,
              tappable: false,
              closedShape: const RoundedRectangleBorder(),
              closedElevation: 0.0,
              closedBuilder: (BuildContext _, VoidCallback openContainer) {
                return ListTile(
                  // leading: Image.asset(
                  //   'assets/avatar_logo.png',
                  //   width: 40,
                  // ),
                  onTap: openContainer,
                  title: Text('List item ${index + 1}'),
                  subtitle: const Text('Secondary text'),
                );
              },
            );
          }),
        ],
      ),
      floatingActionButton: OpenContainer(
        transitionType: _transitionType,
        openBuilder: (BuildContext context, VoidCallback _) {
          return const _DetailsPage(
            includeMarkAsDoneButton: false,
          );
        },
        closedElevation: 6.0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(_fabDimension / 2),
          ),
        ),
        closedColor: Theme.of(context).colorScheme.secondary,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return SizedBox(
            height: _fabDimension,
            width: _fabDimension,
            child: Center(
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OpenContainerWrapper extends StatelessWidget {
  const _OpenContainerWrapper({
    required this.closedBuilder,
    required this.transitionType,
    required this.onClosed,
  });

  final CloseContainerBuilder closedBuilder;
  final ContainerTransitionType transitionType;
  final ClosedCallback<bool?> onClosed;

  @override
  Widget build(BuildContext context) {
    return OpenContainer<bool>(
      transitionType: transitionType,
      openBuilder: (BuildContext context, VoidCallback _) {
        return const _DetailsPage();
      },
      onClosed: onClosed,
      tappable: false,
      closedBuilder: closedBuilder,
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.openContainer});

  final VoidCallback openContainer;

  @override
  Widget build(BuildContext context) {
    return _InkWellOverlay(
      openContainer: openContainer,
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Expanded(
          //   child: ColoredBox(
          //     color: Colors.black38,
          //     child: Center(
          //       child: Image.asset(
          //         'assets/placeholder_image.png',
          //         width: 100,
          //       ),
          //     ),
          //   ),
          // ),
          const ListTile(
            title: Text('Title'),
            subtitle: Text('Secondary text'),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: Text(
              'Lorem ipsum dolor sit amet, consectetur '
              'adipiscing elit, sed do eiusmod tempor.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallerCard extends StatelessWidget {
  const _SmallerCard({
    required this.openContainer,
    required this.subtitle,
  });

  final VoidCallback openContainer;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _InkWellOverlay(
      openContainer: openContainer,
      height: 225,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            color: Colors.black38,
            height: 150,
            // child: Center(
            //   child: Image.asset(
            //     'assets/placeholder_image.png',
            //     width: 80,
            //   ),
            // ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Title',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleSingleTile extends StatelessWidget {
  const _ExampleSingleTile({required this.openContainer});

  final VoidCallback openContainer;

  @override
  Widget build(BuildContext context) {
    const double height = 100.0;

    return _InkWellOverlay(
      openContainer: openContainer,
      height: height,
      child: Row(
        children: <Widget>[
          Container(
            color: Colors.black38,
            height: height,
            width: height,
            // child: Center(
            //   child: Image.asset(
            //     'assets/placeholder_image.png',
            //     width: 60,
            //   ),
            // ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Title',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Lorem ipsum dolor sit amet, consectetur '
                      'adipiscing elit,',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InkWellOverlay extends StatelessWidget {
  const _InkWellOverlay({
    this.openContainer,
    this.height,
    this.child,
  });

  final VoidCallback? openContainer;
  final double? height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: InkWell(
        onTap: openContainer,
        child: child,
      ),
    );
  }
}

class _DetailsPage extends StatelessWidget {
  const _DetailsPage({this.includeMarkAsDoneButton = true});

  final bool includeMarkAsDoneButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details page'),
        actions: <Widget>[
          if (includeMarkAsDoneButton)
            IconButton(
              icon: const Icon(Icons.done),
              onPressed: () => Navigator.pop(context, true),
              tooltip: 'Mark as done',
            )
        ],
      ),
      body: ListView(
        children: <Widget>[
          Container(
            color: Colors.black38,
            height: 250,
            // child: Padding(
            //   padding: const EdgeInsets.all(70.0),
            //   child: Image.asset(
            //     'assets/placeholder_image.png',
            //   ),
            // ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Title',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Colors.black54,
                        fontSize: 30.0,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  _loremIpsumParagraph,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.black54,
                        height: 1.5,
                        fontSize: 16.0,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
  return testData.substring(next(0, testData.length - length - 1), length);
}

List<Account> generateTestData(int length) {
  final List<Account> list = [];
  for (int i = 0; i < length; i++) {
    list.add(
      Account(
          account: getRandomData(5),
          domainName: getRandomData(8),
          domain: getRandomData(10),
          email: getRandomData(10),
          password: getRandomData(15),
          description: getRandomData(100),
          labels: [getRandomData(4), getRandomData(10), getRandomData(8)]),
    );
  }
  return list;
}
