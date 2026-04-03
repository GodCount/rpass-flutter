#include "include/common_native_channel/common_native_channel_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "common_native_channel_plugin.h"

void CommonNativeChannelPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  common_native_channel::CommonNativeChannelPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
