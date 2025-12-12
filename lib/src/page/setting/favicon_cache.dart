import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../store/index.dart';
import '../../util/fetch_favicon.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';

class _FavIconCacheArgs extends PageRouteArgs {
  _FavIconCacheArgs({super.key});
}

class FavIconCacheRoute extends PageRouteInfo<_FavIconCacheArgs> {
  FavIconCacheRoute({
    Key? key,
  }) : super(
          name,
          args: _FavIconCacheArgs(key: key),
        );

  static const name = "FavIconCacheRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_FavIconCacheArgs>(
        orElse: () => _FavIconCacheArgs(),
      );
      return FavIconCachePage(key: args.key);
    },
  );
}

class FavIconCachePage extends StatefulWidget {
  const FavIconCachePage({super.key});

  @override
  State<FavIconCachePage> createState() => _FavIconCachePageState();
}

class _FavIconCachePageState extends State<FavIconCachePage>
    with SecondLevelPageAutoBack<FavIconCachePage> {
  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.more_settings),
      ),
      body: ListView(
        children: [],
      ),
    );
  }
}
