#include "prev_focus_window_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <io.h>



// Convert wstring into utf8 string
static std::string toUtf8(const std::wstring& str) {
	std::string ret;
	int len = WideCharToMultiByte(CP_UTF8, 0, str.c_str(), static_cast<int>(str.length()), NULL, 0, NULL, NULL);
	if (len > 0) {
		ret.resize(len);
		WideCharToMultiByte(CP_UTF8, 0, str.c_str(), static_cast<int>(str.length()), &ret[0], len, NULL, NULL);
	}

	return ret;
}

// Return window title in utf8 string
static std::string getWindowTitle(const HWND hwnd) {
	int  bufsize = static_cast<int>(GetWindowTextLengthW(hwnd)) + 1;
	LPWSTR t = new WCHAR[bufsize];
	GetWindowTextW(hwnd, t, bufsize);

	std::wstring ws(t);
	std::string title = toUtf8(ws);

	return title;
}





namespace prev_focus_window {


	std::unique_ptr<
		flutter::MethodChannel<flutter::EncodableValue>,
		std::default_delete<flutter::MethodChannel<flutter::EncodableValue>>>
		channel = nullptr;

	HWINEVENTHOOK h_hook = nullptr;

	HWND selfWin = nullptr;
	HWND prevForegroundWin = nullptr;

	// static
	void PrevFocusWindowPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar) {

		channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
			registrar->messenger(), "prev_focus_window",
			&flutter::StandardMethodCodec::GetInstance());

		auto plugin = std::make_unique<PrevFocusWindowPlugin>();

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




	void CALLBACK PrevFocusWindowPlugin::HandleWinEventProc(HWINEVENTHOOK hWinEventHook, DWORD event, HWND hwnd,
		LONG idObject, LONG idChild, DWORD dwEventThread, DWORD dwmsEventTime) {

		if (selfWin == nullptr || selfWin == hwnd || prevForegroundWin == hwnd) return;

		if (event == EVENT_SYSTEM_FOREGROUND) {

			std::string title = getWindowTitle(hwnd);

			// exclude title is empty HWND
			if (title.empty()) return;

			prevForegroundWin = hwnd;

			flutter::EncodableMap args = flutter::EncodableMap();
			args[flutter::EncodableValue("name")] = flutter::EncodableValue(title);
			channel->InvokeMethod("prev_actived_window", std::make_unique<flutter::EncodableValue>(args));
		}
	}



	PrevFocusWindowPlugin::PrevFocusWindowPlugin() {}



	PrevFocusWindowPlugin::~PrevFocusWindowPlugin() {
		channel = nullptr;
		selfWin = nullptr;
		prevForegroundWin = nullptr;
		UnhookWinEvent(h_hook);
	}


	void PrevFocusWindowPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
		std::string method_name = method_call.method_name();

		if (method_name.compare("activate_prev_window") == 0) {
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





}  // namespace prev_focus_window
