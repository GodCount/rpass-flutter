import 'dart:ui';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../context/kdbx.dart';
import '../../i18n.dart';
import '../../kdbx/detection.dart';
import '../../util/common.dart';
import '../../util/route.dart';
import '../../widget/common.dart';
import '../../widget/extension_state.dart';
import 'route_wrap.dart';

class DetectionArgs extends PageRouteArgs {
  DetectionArgs({super.key});
}

class DetectionRoute extends PageRouteInfo<DetectionArgs> {
  DetectionRoute({
    Key? key,
  }) : super(
          name,
          args: DetectionArgs(key: key),
        );

  static const name = "DetectionRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DetectionArgs>(
        orElse: () => DetectionArgs(),
      );
      return DetectionPage(key: args.key);
    },
  );
}

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => DetectionPageState();
}

class DetectionPageState extends State<DetectionPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final KdbxDetectionController _detectionController =
      KdbxDetectionController(KdbxProvider.of(context)!);

  @override
  void initState() {
    super.initState();
    _detectionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    _detectionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return isDesktop ? RouteWrap(child: _buildMobile()) : _buildMobile();
  }

  Widget _buildMobile() {
    final t = I18n.of(context)!;

    return Scaffold(
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (_, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              stretch: true,
              forceElevated: innerBoxIsScrolled,
              flexibleSpace: LayoutBuilder(
                builder: (_, constraints) {
                  final color = _detectionController.isDetecting
                      ? Colors.grey
                      : Colors.blue;
                  final maxHeight = clampDouble(
                    (constraints.maxHeight - 100),
                    40.0,
                    76.0,
                  );

                  return FlexibleSpaceBar(
                    centerTitle: true,
                    expandedTitleScale: 1,
                    title: constraints.maxHeight > 110
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: clampDouble(
                              24 * constraints.maxHeight / 240,
                              8,
                              24,
                            ),
                            children: [
                              GestureTapScale(
                                onTap: () {
                                  if (_detectionController.isDetecting) {
                                    _detectionController.cancel();
                                  } else {
                                    _detectionController.detect();
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  constraints: BoxConstraints(
                                    maxHeight: maxHeight,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(999999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: .4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    _detectionController.isDetecting
                                        ? t.cancel
                                        : t.detection,
                                    textScaler:
                                        TextScaler.linear(maxHeight / 76.0),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  _detectionController.currentEntry != null
                                      ? getKdbxObjectTitle(
                                          _detectionController.currentEntry!,
                                        )
                                      : "检测密码库",
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  textScaler: TextScaler.linear(
                                    clampDouble(
                                      (constraints.maxHeight - 140) / 100,
                                      0.6,
                                      0.8,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: constraints.maxWidth,
                              )
                            ],
                          )
                        : Text(t.detection),
                  );
                },
              ),
            )
          ];
        },
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            SizedBox(height: kToolbarHeight + 12),
            Row(
              spacing: 12,
              children: [
                _cardTile(
                  title: "弱密码",
                  count: _detectionController.weakPassList.length,
                  onTap: () {},
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              spacing: 12,
              children: [
                _cardTile(
                  title: "过期",
                  count: _detectionController.expiredPassList.length,
                  onTap: () {},
                ),
                _cardTile(
                  title: "附件引用",
                  count: _detectionController.binaryList.length,
                  onTap: () {},
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardTile({
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureTapScale(
        onTap: onTap,
        child: Card(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          child: Container(
            height: 96.0,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AnimatedFlipCounter(
                            duration: const Duration(milliseconds: 200),
                            value: count,
                            mainAxisAlignment: MainAxisAlignment.start,
                            textStyle: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
