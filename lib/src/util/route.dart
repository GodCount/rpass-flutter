import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

abstract class PageRouteArgs {
  PageRouteArgs({this.key});
  final Key? key;
}

extension _IterableExtension<T> on Iterable<T> {
  T? lastWhereOrNull(bool Function(T element) test) {
    T? result;
    for (var element in this) {
      if (test(element)) result = element;
    }
    return result;
  }
}

extension _PlatformRoutingController on RoutingController {
  RoutingController? _topInnerControllerOfExt(Key? key) {
    return childControllers.lastWhereOrNull(
      (c) => c.key == key,
    );
  }

  List<RoutingController> _buildRoutersHierarchyExt() {
    void collectRouters(
        RoutingController currentParent, List<RoutingController> all) {
      all.add(currentParent);
      if (currentParent.parent() != null) {
        collectRouters(currentParent.parent()!, all);
      }
    }

    final routers = <RoutingController>[this];
    if (parent() != null) {
      collectRouters(parent()!, routers);
    }
    return routers;
  }
}

extension PlatformTabsRouter on TabsRouter {
  AutoRoutePage? get _activePageExt {
    return stack.isEmpty ? null : stack[activeIndex];
  }
}

extension PlatformStackRouter on StackRouter {
  bool _canHandleNavigationExt(PageRouteInfo route) {
    return routeCollection.containsKey(route.routeName);
  }

  StackRouter findStackScope(PageRouteInfo route) {
    final stackRouters = _topMostRouter(this, ignorePagelessRoutes: true)
        ._buildRoutersHierarchyExt()
        .whereType<StackRouter>();
    return stackRouters.firstWhere(
      (c) => c._canHandleNavigationExt(route),
      orElse: () => this,
    );
  }
}

RoutingController _topMostRouter(
  RoutingController router, {
  bool ignorePagelessRoutes = false,
}) {
  if (router is StackRouter) {
    if (router.childControllers.isNotEmpty &&
        (ignorePagelessRoutes || !router.hasPagelessTopRoute)) {
      var topRouteKey = router.currentChild?.key;
      final innerRouter = router._topInnerControllerOfExt(topRouteKey);
      if (innerRouter != null) {
        return _topMostRouter(
          innerRouter,
          ignorePagelessRoutes: ignorePagelessRoutes,
        );
      }
    }
  } else if (router is TabsRouter) {
    final innerRouter = router._topInnerControllerOfExt(
      router._activePageExt?.routeData.key,
    );
    if (innerRouter != null) {
      return _topMostRouter(
        innerRouter,
        ignorePagelessRoutes: ignorePagelessRoutes,
      );
    }
  }
  return router;
}
