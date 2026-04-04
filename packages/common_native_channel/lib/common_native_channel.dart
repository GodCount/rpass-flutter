library;

import 'src/common_native_channel_platform.dart';


export 'src/common_native_channel_platform.dart' show CommonNativeChannelPlatform;
export 'src/features/prev_focus_window.dart' show PrevFocusWindowListener;


final prevFocusWindow = CommonNativeChannelPlatform.instance.prevFocusWindow;

