#include "common_native_channel_plugin.h"
#include "features/prev_focus_window.h"

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>
#include <flutter/method_result_functions.h>

#include <memory>
#include <sstream>
#include <algorithm>

namespace common_native_channel {

	std::unique_ptr<
		flutter::MethodChannel<flutter::EncodableValue>,
		std::default_delete<flutter::MethodChannel<flutter::EncodableValue>>>
		channel = nullptr;

	HWND selfWin = nullptr;

	void CommonNativeChannelPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar) {
		channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
			registrar->messenger(), "common_native_channel",
			&flutter::StandardMethodCodec::GetInstance());


		selfWin = registrar->GetView()->GetNativeWindow();

		auto plugin = std::make_unique<CommonNativeChannelPlugin>();

		channel->SetMethodCallHandler(
			[plugin_pointer = plugin.get()](const auto& call, auto result) {
				plugin_pointer->HandleMethodCall(call, std::move(result));
			});

		registrar->AddPlugin(std::move(plugin));
	}

	CommonNativeChannelPlugin::CommonNativeChannelPlugin()
	{
		features_.push_back(std::make_unique<PrevFocusWindow>(channel.get(), selfWin));
	}

	CommonNativeChannelPlugin::~CommonNativeChannelPlugin() {
		channel = nullptr;
		selfWin = nullptr;
	};

	void CommonNativeChannelPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
		const std::string method = method_call.method_name();

		if (method == "ensure_initialized") {
			result->Success(flutter::EncodableValue(true));
			return;
		}


		for (auto& feature : features_) {
			auto methods = feature->Methods();
			if (std::find(methods.begin(), methods.end(), method) != methods.end()) {
				feature->Handle(method_call, std::move(result));
				return;
			}
		}

		result->NotImplemented();
	}

}  // namespace common_native_channel
