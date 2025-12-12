import 'package:flutter/material.dart';

import '../kdbx/icons.dart';
import '../kdbx/kdbx.dart';
import '../store/index.dart';
import '../util/cache_network_image.dart';
import '../util/fetch_favicon.dart';

class KdbxIconWidgetData {
  KdbxIconWidgetData({
    required this.icon,
    this.customIcon,
    this.domain,
  });

  final KdbxIcon icon;
  final KdbxCustomIcon? customIcon;
  final String? domain;
}

class KdbxIconWidget extends StatelessWidget {
  const KdbxIconWidget({super.key, required this.kdbxIcon, this.size = 32});

  static final FaviconCacheManager _cacheManager = FaviconCacheManager();
  static final FetchFavIcon _fetchFavIcon = FetchFavIcon();

  final KdbxIconWidgetData kdbxIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (kdbxIcon.customIcon != null) {
      return Image.memory(
        kdbxIcon.customIcon!.data,
        width: size,
        height: size,
      );
    }

    final icon = Icon(
      KdbxIcon2Material.to(kdbxIcon.icon),
      size: size,
    );

    if (kdbxIcon.domain == null ||
        Store.instance.settings.favIconSource == null) {
      return icon;
    }

    if (_fetchFavIcon.source != Store.instance.settings.favIconSource) {
      _fetchFavIcon.source = Store.instance.settings.favIconSource!;
    }

    return Image(
      image: CacheNetworkImage(
        kdbxIcon.domain!,
        cacheManager: _cacheManager,
        fetchNetworkImage: _fetchFavIcon,
      ),
      width: size,
      height: size,
      loadingBuilder: (context, child, loadingProgress) {
        if (child is Semantics &&
            child.child is RawImage &&
            (child.child! as RawImage).image != null) {
          return child;
        }
        return icon;
      },
      errorBuilder: (context, error, stackTrace) {
        return icon;
      },
    );
  }
}
