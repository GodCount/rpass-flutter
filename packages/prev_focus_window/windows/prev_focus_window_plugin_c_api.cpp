#include "include/prev_focus_window/prev_focus_window_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "prev_focus_window_plugin.h"

void PrevFocusWindowPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  prev_focus_window::PrevFocusWindowPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
