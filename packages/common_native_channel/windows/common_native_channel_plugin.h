#ifndef FLUTTER_PLUGIN_COMMON_NATIVE_CHANNEL_PLUGIN_H_
#define FLUTTER_PLUGIN_COMMON_NATIVE_CHANNEL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace common_native_channel {

class CommonNativeChannelPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  CommonNativeChannelPlugin();

  virtual ~CommonNativeChannelPlugin();

  // Disallow copy and assign.
  CommonNativeChannelPlugin(const CommonNativeChannelPlugin&) = delete;
  CommonNativeChannelPlugin& operator=(const CommonNativeChannelPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace common_native_channel

#endif  // FLUTTER_PLUGIN_COMMON_NATIVE_CHANNEL_PLUGIN_H_
