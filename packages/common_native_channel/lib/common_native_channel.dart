library;

import 'src/common_native_channel_platform.dart';


export 'src/common_native_channel_platform.dart' show CommonNativeChannelPlatform;
export 'src/common_features_interface.dart' show CommonFeaturesInterface;
export 'src/features/prev_focus_window.dart' show PrevFocusWindowListener;
export 'src/features/installed_apps.dart' show AppInfo;

final prevFocusWindow = CommonNativeChannelPlatform.instance.prevFocusWindow;
final installedApps = CommonNativeChannelPlatform.instance.installedApps;
