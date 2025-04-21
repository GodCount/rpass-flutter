import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

abstract class PageRouteArgs {
  PageRouteArgs({this.key});
  final Key? key;
}

extension PlatformStackRouter on StackRouter {
  bool _canHandleNavigationExt(PageRouteInfo route) {
    return routeCollection.containsKey(route.routeName);
  }

  StackRouter findStackScope(PageRouteInfo route) {
    if (_canHandleNavigationExt(route)) {
      return this;
    }

    StackRouter? findChild(RoutingController router) {
      if (router is StackRouter && router._canHandleNavigationExt(route)) {
        return router;
      }

      for (RoutingController item in router.childControllers) {
        if (item == this) continue;
        final result = findChild(item);
        if (result != null) return result;
      }
      return null;
    }

    return findChild(root) ?? this;
  }
}
