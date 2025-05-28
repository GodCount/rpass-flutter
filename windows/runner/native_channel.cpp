#include "native_channel.h"

#include <codecvt>
#include <memory>
#include <optional>
#include <sstream>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>


#include "utils.h"

namespace {

	std::unique_ptr<
		flutter::MethodChannel<flutter::EncodableValue>,
		std::default_delete<flutter::MethodChannel<flutter::EncodableValue>>>
		channel = nullptr;

	HWINEVENTHOOK h_hook = nullptr;

	HWND selfWin = nullptr;
	HWND prevForegroundWin = nullptr;

	POINT min_size = { 413, 640 };

	POINT max_size = { -1, -1 };

	double scale_factor = 1;



	void CALLBACK HandleWinEventProc(HWINEVENTHOOK hWinEventHook, DWORD event, HWND hwnd,
		LONG idObject, LONG idChild, DWORD dwEventThread, DWORD dwmsEventTime) {

		if (selfWin == nullptr || selfWin == hwnd || prevForegroundWin == hwnd) return;

		if (event == EVENT_SYSTEM_FOREGROUND) {

			prevForegroundWin = hwnd;

			flutter::EncodableMap args = flutter::EncodableMap();
			args[flutter::EncodableValue("name")] = flutter::EncodableValue(getWindowTitle(hwnd));
			channel->InvokeMethod("prev_actived_application", std::make_unique<flutter::EncodableValue>(args));
		}
	}


	class RpassPlugin : public flutter::Plugin {
	public:
		static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

		RpassPlugin(flutter::PluginRegistrarWindows* registrar);

		virtual ~RpassPlugin();

	private:
		flutter::PluginRegistrarWindows* registrar;

		// The ID of the WindowProc delegate registration.
		int window_proc_id = -1;

		// Called for top-level WindowProc delegation.
		std::optional<LRESULT> RpassPlugin::HandleWindowProc(HWND hWnd,
			UINT message,
			WPARAM wParam,
			LPARAM lParam);

		// Called when a method is called on this plugin's channel from Dart.
		void RpassPlugin::HandleMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

	};


	void RpassPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {

		scale_factor = ScaleFactor(10, 10);

		channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
			registrar->messenger(), "native_channel_rpass",
			&flutter::StandardMethodCodec::GetInstance());

		auto plugin = std::make_unique<RpassPlugin>(registrar);

		channel->SetMethodCallHandler(
			[plugin_pointer = plugin.get()](const auto& call, auto result) {
				plugin_pointer->HandleMethodCall(call, std::move(result));
			});

		selfWin = registrar->GetView()->GetNativeWindow();

		h_hook = SetWinEventHook(
			EVENT_SYSTEM_FOREGROUND,
			EVENT_SYSTEM_FOREGROUND,
			NULL,
			HandleWinEventProc,
			0, 0,
			WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS
		);

		registrar->AddPlugin(std::move(plugin));
	}

	RpassPlugin::RpassPlugin(
		flutter::PluginRegistrarWindows* registrar)
		: registrar(registrar) {
		window_proc_id = registrar->RegisterTopLevelWindowProcDelegate(
			[this](HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
				return HandleWindowProc(hWnd, message, wParam, lParam);
			});

	}

	RpassPlugin::~RpassPlugin() {
		registrar->UnregisterTopLevelWindowProcDelegate(window_proc_id);
		channel = nullptr;
		selfWin = nullptr;
		prevForegroundWin = nullptr;
		UnhookWinEvent(h_hook);
	}



	std::optional<LRESULT> RpassPlugin::HandleWindowProc(HWND hWnd,
		UINT message,
		WPARAM wParam,
		LPARAM lParam) {

		if (message == WM_GETMINMAXINFO) {
			MINMAXINFO* info = reinterpret_cast<MINMAXINFO*>(lParam);
			if (min_size.x != 0) info->ptMinTrackSize.x = Scale(min_size.x, scale_factor);
			if (min_size.y != 0) info->ptMinTrackSize.y = Scale(min_size.y, scale_factor);
			if (max_size.x != -1) info->ptMaxTrackSize.x = Scale(max_size.x, scale_factor);
			if (max_size.y != -1) info->ptMaxTrackSize.y = Scale(max_size.y, scale_factor);
			return 0;
		}

		return std::nullopt;
	}


	void RpassPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
		std::string method_name = method_call.method_name();

		if (method_name.compare("activate_prev_application") == 0) {
			if (prevForegroundWin != nullptr) {
				if (SetForegroundWindow(prevForegroundWin)) {
					return result->Success(flutter::EncodableValue(true));
				}
				prevForegroundWin = nullptr;
			}
			result->Success(flutter::EncodableValue(false));
		}
		else {
			result->NotImplemented();
		}
	}




}




void RegisterRpassPlugin(FlutterDesktopPluginRegistrarRef registrar) {
	RpassPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarManager::GetInstance()
		->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}