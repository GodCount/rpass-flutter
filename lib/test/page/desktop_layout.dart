import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:window_manager/window_manager.dart';

class ResizableGridContainer extends StatefulWidget {
  @override
  State<ResizableGridContainer> createState() => ResizableGridContainerState();
}

class ResizableGridContainerState extends State<ResizableGridContainer> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

class DesktopLayoutPage extends StatefulWidget {
  const DesktopLayoutPage({super.key});

  static const routeName = "/Desktop_Layout";

  @override
  State<DesktopLayoutPage> createState() => DesktopLayoutPageState();
}

class DesktopLayoutPageState extends State<DesktopLayoutPage>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  // @override
  // void onWindowResize() async {
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return ResizableContainer(
      direction: Axis.horizontal,
      children: [
        ResizableChild(
          size: const ResizableSize.shrink(min: 64),
          child: SizedBox(
            width: 64,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const SizeLabel(),
            ),
          ),
        ),
        ResizableChild(
          size: const ResizableSize.shrink(min: 350),
          child: SizedBox(
            width: 350,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const SizeLabel(),
            ),
          ),
        ),
        ResizableChild(
          size: const ResizableSize.expand(),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: const SizeLabel(),
          ),
        ),
      ],
    );
  }
}

class SizeLabel extends StatelessWidget {
  const SizeLabel({super.key, this.minSize, this.maxSize});

  final double? minSize;
  final double? maxSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight.toStringAsFixed(2);
      final width = constraints.maxWidth.toStringAsFixed(2);

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Height: $height', textAlign: TextAlign.center),
            Text('Width: $width', textAlign: TextAlign.center),
            if (minSize != null) Text("MinSize: $minSize"),
            if (maxSize != null) Text("MinSize: $maxSize")
          ],
        ),
      );
    });
  }
}
