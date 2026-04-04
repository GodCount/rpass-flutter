#ifndef FLUTTER_PLUGIN_COMMON_NATIVE_CHANNEL_PLUGIN_H_
#define FLUTTER_PLUGIN_COMMON_NATIVE_CHANNEL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include "common_features_interface.h"

#include <memory>
#include <string>
#include <vector>

namespace common_native_channel {

	class CommonNativeChannelPlugin : public flutter::Plugin {
	public:
		static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

		explicit CommonNativeChannelPlugin();

		~CommonNativeChannelPlugin() override;

		CommonNativeChannelPlugin(const CommonNativeChannelPlugin&) = delete;
		CommonNativeChannelPlugin& operator=(const CommonNativeChannelPlugin&) = delete;

		void HandleMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

	private:
		std::vector<std::unique_ptr<CommonFeaturesInterface>> features_;
	};

}  // namespace common_native_channel

#endif  // FLUTTER_PLUGIN_COMMON_NATIVE_CHANNEL_PLUGIN_H_
