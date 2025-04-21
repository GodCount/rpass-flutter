import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void customErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    return ReleaseModeErrorWidget(details: details);
  };
}

class ReleaseModeErrorWidget extends StatelessWidget {
  const ReleaseModeErrorWidget({
    super.key,
    required this.details,
  });

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListTile(
        isThreeLine: true,
        title: Text("Build Error:\n${details.exception}"),
        subtitle: Text("Stack:\n ${details.stack}"),
      ),
    );
  }
}
