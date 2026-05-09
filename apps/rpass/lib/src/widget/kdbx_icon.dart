import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../context/kdbx.dart';
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
    this.customIconUuid,
    this.customIcon,
    this.source,
    String? domain,
  }) : domain = domain != null ? domain.simpleToDomain().toLowerCase() : domain;

  final KdbxIcon icon;
  final KdbxUuid? customIconUuid;
  final KdbxCustomIcon? customIcon;
  // TODO! url 现在是支持复数个了 KdbxKeyURLS favicon 需要兼容
  final String? domain;
  final FaviconSource? source;

  Uint8List? getCustomIcon(Kdbx kdbx) {
    if (customIconUuid != null &&
        kdbx.customIcons.containsKey(customIconUuid)) {
      return kdbx.getCustomIcon(customIconUuid!);
    } else if (customIcon != null) {
      return Uint8List.fromList(customIcon!.data);
    }
    return null;
  }

  KdbxIconWidgetData copyWith({
    KdbxIcon? icon,
    KdbxUuid? customIconUuid,
    KdbxCustomIcon? customIcon,
    FaviconSource? source,
    String? domain,
  }) {
    return KdbxIconWidgetData(
      icon: icon ?? this.icon,
      customIconUuid: customIconUuid ?? this.customIconUuid,
      customIcon: customIcon ?? this.customIcon,
      source: source ?? this.source,
      domain: domain ?? this.domain,
    );
  }
}

class KdbxIconWidget extends StatelessWidget {
  const KdbxIconWidget({
    super.key,
    required this.kdbxIcon,
    this.size = 32,
    this.errorCallback,
  });

  static final FaviconCacheManager cacheManager = FaviconCacheManager();

  final KdbxIconWidgetData kdbxIcon;
  final double size;
  final ImageLoadErrorCallback? errorCallback;

  @override
  Widget build(BuildContext context) {
    final kdbx = KdbxProvider.of(context).kdbx!;
    final customIcon = kdbxIcon.getCustomIcon(kdbx);

    if (customIcon != null) {
      return Image.memory(customIcon, width: size, height: size);
    }

    final faviconSource = Store.instance.settings.faviconSource;

    final icon = Icon(KdbxIcon2Material.to(kdbxIcon.icon), size: size);

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
          child:
              child is Semantics &&
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
