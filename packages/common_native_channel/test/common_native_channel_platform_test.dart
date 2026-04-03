import 'package:flutter_test/flutter_test.dart';
import 'package:common_native_channel/common_native_channel.dart';
import 'package:common_native_channel/common_native_channel_platform.dart';

void main() {
  final CommonNativeChannelPlatform initialPlatform =
      CommonNativeChannelPlatform.instance;

  test('$CommonNativeChannelPlatform is the default instance', () {
    expect(initialPlatform, isInstanceOf<CommonNativeChannelPlatform>());
  });

  test('features methodCalls repeat', () async {
    final methodCalls = initialPlatform.features.fold<List<String>>(
      [],
      (list, item) => list..addAll(item.methodCalls),
    );

    expect(methodCalls.length, methodCalls.toSet().length);
  });
}
