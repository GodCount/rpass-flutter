import 'package:flutter/material.dart';

import '../kdbx/icons.dart';
import '../kdbx/kdbx.dart';
import '../store/index.dart';
import '../util/cache_network_image.dart';
import '../util/common.dart';
import '../util/fetch_favicon.dart';

typedef ImageLoadErrorCallback = void Function(Object error);

class KdbxIconWidgetData {
  KdbxIconWidgetData({
    required this.icon,
    this.customIcon,
    this.source,
    String? domain,
  }) : domain = domain != null ? domain.simpleToDomain().toLowerCase() : domain;

  final KdbxIcon icon;
  final KdbxCustomIcon? customIcon;
  final String? domain;
  final FaviconSource? source;

  KdbxIconWidgetData copyWith({
    KdbxIcon? icon,
    KdbxCustomIcon? customIcon,
    FaviconSource? source,
    String? domain,
  }) {
    return KdbxIconWidgetData(
      icon: icon ?? this.icon,
      customIcon: customIcon ?? this.customIcon,
      source: source ?? this.source,
      domain: domain ?? this.domain,
    );
  }
}

class KdbxIconWidget extends StatelessWidget {
  const KdbxIconWidget(
      {super.key, required this.kdbxIcon, this.size = 32, this.errorCallback});

  static final FaviconCacheManager cacheManager = FaviconCacheManager();

  final KdbxIconWidgetData kdbxIcon;
  final double size;
  final ImageLoadErrorCallback? errorCallback;

  @override
  Widget build(BuildContext context) {
    if (kdbxIcon.customIcon != null) {
      return Image.memory(
        kdbxIcon.customIcon!.data,
        width: size,
        height: size,
      );
    }

    final faviconSource = Store.instance.settings.faviconSource;

    final icon = Icon(
      KdbxIcon2Material.to(kdbxIcon.icon),
      size: size,
    );

    if (kdbxIcon.domain == null ||
        kdbxIcon.domain!.isEmpty ||
        (faviconSource == null && kdbxIcon.source == null)) {
      return icon;
    }

    final source = kdbxIcon.source ?? faviconSource!;

    return Image(
      image: CacheNetworkImage(
        kdbxIcon.domain!,
        cacheManager: cacheManager,
        fetchNetworkImage: FetchFavicon(source),
      ),
      width: size,
      height: size,
      loadingBuilder: (context, child, loadingProgress) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: child is Semantics &&
                  child.child is RawImage &&
                  (child.child! as RawImage).image != null
              ? child
              : icon,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (errorCallback != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            errorCallback?.call(error);
          });
        }

        return icon;
      },
    );
  }
}
