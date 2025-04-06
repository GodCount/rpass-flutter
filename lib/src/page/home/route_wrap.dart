import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../widget/extension_state.dart';

class RouteWrap extends StatefulWidget {
  const RouteWrap({
    super.key,
    required this.child,
    this.empty = const EmptyPage(),
  });

  final Widget child;
  final Widget empty;

  @override
  State<RouteWrap> createState() => _RouteWrapState();
}

class _RouteWrapState extends State<RouteWrap>
    with SecondLevelRouteUtil<RouteWrap> {
  @override
  void didEmptyRouteChange() {
    setState(() {});
  }

  @override
  void didCriticalChange({
    required bool oldIsIdeaSrceen,
    required bool oldIsSingleScreen,
  }) {
    if (oldIsSingleScreen != isSingleScreen) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final leftOffstage = isSingleScreen && !isEmptyRouter;
          final rightOffstage = isSingleScreen && isEmptyRouter;

          double leftWidth = (constraints.maxWidth / 2).clamp(250, 375);
          double rightWidth = max(constraints.maxWidth - leftWidth, 0);

          if (!leftOffstage && rightOffstage) {
            leftWidth = constraints.maxWidth;
          } else if (!rightOffstage && leftOffstage) {
            rightWidth = constraints.maxWidth;
          }

          return Row(
            children: [
              Offstage(
                offstage: leftOffstage,
                child: Container(
                  width: leftWidth,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 3,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: widget.child,
                  ),
                ),
              ),
              Offstage(
                offstage: rightOffstage,
                child: Container(
                  width: rightWidth,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 3,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: IndexedStack(
                      index: isEmptyRouter ? 1 : 0,
                      children: [const AutoRouter(), widget.empty],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EmptyPage extends StatelessWidget {
  const EmptyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Center(
      child: Text(
        t.empty,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
