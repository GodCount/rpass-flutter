//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <common_native_channel/common_native_channel_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) common_native_channel_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "CommonNativeChannelPlugin");
  common_native_channel_plugin_register_with_registrar(common_native_channel_registrar);
}
