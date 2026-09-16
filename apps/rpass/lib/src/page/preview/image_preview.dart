import 'dart:math';
import 'dart:ui' as ui;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_zoom/photo_zoom.dart';

import '../../util/common.dart';
import '../../util/route.dart';

class _ImagePreviewArgs extends PageRouteArgs {
  _ImagePreviewArgs({
    super.key,
    required this.initialIndex,
    required this.items,
  });
  final int initialIndex;
  final List<GalleryItem> items;
}

class ImagePreviewRoute extends PageRouteInfo<_ImagePreviewArgs> {
  ImagePreviewRoute({
    Key? key,
    required int initialIndex,
    required List<GalleryItem> items,
  }) : super(
         name,
         args: _ImagePreviewArgs(
           key: key,
           initialIndex: initialIndex,
           items: items,
         ),
       );

  static const name = "ImagePreviewRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_ImagePreviewArgs>(
        orElse: () => _ImagePreviewArgs(initialIndex: -1, items: []),
      );
      return ImagePreviewPage(
        key: args.key,
        initialIndex: args.initialIndex,
        items: args.items,
      );
    },
  );
}

class ImagePreviewPage extends StatefulWidget {
  const ImagePreviewPage({
    super.key,
    required this.initialIndex,
    required this.items,
  });

  final int initialIndex;
  final List<GalleryItem> items;

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage>
    with SingleTickerProviderStateMixin {
  late int currentIndex;
  late PageController _controller;

  late final AnimationController _chromeController;
  late final CurvedAnimation _chromeCurve;
  late final Animation<Offset> _titleOffset;
  late final Animation<Offset> _footerOffset;

  late final Animation<Offset> _prevOffset;
  late final Animation<Offset> _nextOffset;

  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    currentIndex = min(max(0, widget.initialIndex), widget.items.length - 1);
    _controller = PageController(initialPage: currentIndex);

    _chromeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    _chromeCurve = CurvedAnimation(
      parent: _chromeController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _titleOffset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(_chromeCurve);

    _footerOffset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(_chromeCurve);

    _prevOffset = Tween<Offset>(
      begin: const Offset(-1.1, 0),
      end: Offset.zero,
    ).animate(_chromeCurve);

    _nextOffset = Tween<Offset>(
      begin: const Offset(1.1, 0),
      end: Offset.zero,
    ).animate(_chromeCurve);

    _applySystemUi();
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  void _toggleChrome() {
    _chromeVisible = !_chromeVisible;
    if (_chromeVisible) {
      _chromeController.forward();
    } else {
      _chromeController.reverse();
    }
    _applySystemUi();
  }

  void _applySystemUi() {
    if (kIsMobile) {
      SystemChrome.setEnabledSystemUIMode(
        _chromeVisible ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
      );
    }
  }

  void _restoreSystemUi() {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _controller.dispose();
    _chromeCurve.dispose();
    _chromeController.dispose();
    _restoreSystemUi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            context.pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Container(
            decoration: const BoxDecoration(color: Colors.black),
            constraints: BoxConstraints.expand(
              height: MediaQuery.of(context).size.height,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: PhotoViewGallery.builder(
                    scrollPhysics: const BouncingScrollPhysics(),
                    builder: _buildItem,
                    pageController: _controller,
                    itemCount: widget.items.length,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    onPageChanged: onPageChanged,
                    scrollDirection: Axis.horizontal,
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _titleOffset,
                    child: _buildTitleBar(),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _footerOffset,
                    child: _buildFooter(),
                  ),
                ),

                // 不支持手势切换的, 桌面端不支持
                if (isDesktop && widget.items.length > 1)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: SlideTransition(
                        position: _prevOffset,
                        child: IconButton(
                          onPressed: currentIndex > 0
                              ? () => _controller.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                )
                              : null,
                          icon: Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                      ),
                    ),
                  ),

                if (isDesktop && widget.items.length > 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SlideTransition(
                        position: _nextOffset,
                        child: IconButton(
                          onPressed: currentIndex < widget.items.length - 1
                              ? () => _controller.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                )
                              : null,
                          icon: Icon(Icons.arrow_forward_ios_rounded),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      color: Colors.black45,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  widget.items[currentIndex].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: Colors.black45,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '${currentIndex + 1} / ${widget.items.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final GalleryItem item = widget.items[index];
    return PhotoViewGalleryPageOptions(
      imageProvider: item.imageProvider,
      initialScale: PhotoViewComputedScale.contained,
      onTapUp: (_, _, _) => _toggleChrome(), // 点击图片切换
    );
  }
}

class GalleryItem {
  GalleryItem({required this.title, required this.imageProvider});

  final LazyMemoryImage imageProvider;
  final String title;
}

typedef BytesLoader = Future<Uint8List> Function();

class LazyMemoryImage extends ImageProvider<LazyMemoryImage> {
  LazyMemoryImage(this.id, this.loader, {this.scale = 1.0});

  final Object id;

  final BytesLoader loader;
  final double scale;

  @override
  Future<LazyMemoryImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<LazyMemoryImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    LazyMemoryImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: 'LazyMemoryImage($id)',
    );
  }

  Future<ui.Codec> _loadAsync(
    LazyMemoryImage key,
    ImageDecoderCallback decode,
  ) async {
    assert(key == this);
    final bytes = await loader();
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LazyMemoryImage && other.id == id && other.scale == scale);

  @override
  int get hashCode => Object.hash(id, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'LazyMemoryImage')}(id: $id, scale: $scale)';
}
