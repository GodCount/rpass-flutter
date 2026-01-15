#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>



void SetMethodHandler(flutter::FlutterEngine* registry) {


	flutter::MethodChannel channel(registry->messenger(), "com.example",
		&flutter::StandardMethodCodec::GetInstance());

	//auto plugin = std::make_unique<WindowManagerPlugin>(exampleRegister);

	HWND topWindow = nullptr;

	channel.SetMethodCallHandler(
		[&topWindow](const auto& call, auto result) {
			std::string method_name = call.method_name();
			if (method_name.compare("recordTopWindow") == 0) {
				topWindow = GetForegroundWindow();
				//int cTxtLen = GetWindowTextLength(topWindow);
				//wchar_t* title{};
				//GetWindowText(topWindow, title,
				//	cTxtLen + 1);

				result->Success(flutter::EncodableValue("title"));
			}
			else if (method_name.compare("setTopWindow") == 0) {
				if (topWindow != nullptr) {
					SetFocus(topWindow);
					topWindow = nullptr;
					result->Success(flutter::EncodableValue(true));
				}
				else {
					result->Success(flutter::EncodableValue(false));
				}
			}
			else {
				result->NotImplemented();
			}
		});

	//exampleRegister->AddPlugin(std::move(plugin));

}


FlutterWindow::FlutterWindow(const flutter::DartProject& project)
	: project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
	if (!Win32Window::OnCreate()) {
		return false;
	}

	RECT frame = GetClientArea();

	// The size here must match the window dimensions to avoid unnecessary surface
	// creation / destruction in the startup path.
	flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
		frame.right - frame.left, frame.bottom - frame.top, project_);
	// Ensure that basic setup of the controller was successful.
	if (!flutter_controller_->engine() || !flutter_controller_->view()) {
		return false;
	}
	RegisterPlugins(flutter_controller_->engine());
	SetMethodHandler(flutter_controller_->engine());
	SetChildContent(flutter_controller_->view()->GetNativeWindow());

	flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });

	// Flutter can complete the first frame before the "show window" callback is
	// registered. The following call ensures a frame is pending to ensure the
	// window is shown. It is a no-op if the first frame hasn't completed yet.
	flutter_controller_->ForceRedraw();

	return true;
}



void FlutterWindow::OnDestroy() {
	if (flutter_controller_) {
		flutter_controller_ = nullptr;
	}

	Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
	WPARAM const wparam,
	LPARAM const lparam) noexcept {
	// Give Flutter, including plugins, an opportunity to handle window messages.
	if (flutter_controller_) {
		std::optional<LRESULT> result =
			flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
				lparam);
		if (result) {
			return *result;
		}
	}

	switch (message) {
	case WM_FONTCHANGE:
		flutter_controller_->engine()->ReloadSystemFonts();
		break;
	}

	return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
