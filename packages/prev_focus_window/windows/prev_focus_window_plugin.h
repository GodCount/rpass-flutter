#ifndef FLUTTER_PLUGIN_PREV_FOCUS_WINDOW_PLUGIN_H_
#define FLUTTER_PLUGIN_PREV_FOCUS_WINDOW_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace prev_focus_window {




	class PrevFocusWindowPlugin : public flutter::Plugin {
	public:
		static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
		static void CALLBACK HandleWinEventProc(HWINEVENTHOOK hWinEventHook, DWORD event, HWND hwnd,
			LONG idObject, LONG idChild, DWORD dwEventThread, DWORD dwmsEventTime);

		PrevFocusWindowPlugin();

		virtual ~PrevFocusWindowPlugin();

	private:

		// Called for top-level WindowProc delegation.
		std::optional<LRESULT> PrevFocusWindowPlugin::HandleWindowProc(HWND hWnd,
			UINT message,
			WPARAM wParam,
			LPARAM lParam);

		// Called when a method is called on this plugin's channel from Dart.
		void PrevFocusWindowPlugin::HandleMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

	};



}  // namespace prev_focus_window

#endif  // FLUTTER_PLUGIN_PREV_FOCUS_WINDOW_PLUGIN_H_
