#include "prev_focus_window.h"

#include <windows.h>

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>
#include <string>

namespace {

    static std::string ToUtf8(const std::wstring& str) {
        if (str.empty()) return std::string();

        int required = WideCharToMultiByte(CP_UTF8, 0, str.c_str(), -1, nullptr, 0, nullptr, nullptr);
        if (required <= 0) return std::string();

        std::string out;
        out.resize(required);
        int written = WideCharToMultiByte(CP_UTF8, 0, str.c_str(), -1, &out[0], required, nullptr, nullptr);
        if (written <= 0) return std::string();

        if (!out.empty() && out.back() == '\0') out.pop_back();
        return out;
    }

    static std::string GetWindowTitle(const HWND hwnd) {
        if (hwnd == nullptr) return std::string();

        int len = GetWindowTextLengthW(hwnd);
        if (len <= 0) return std::string();

        std::wstring buffer;
        buffer.resize(len + 1);
        int copied = GetWindowTextW(hwnd, &buffer[0], len + 1);
        if (copied <= 0) return std::string();

        if (!buffer.empty() && buffer.back() == L'\0') buffer.pop_back();
        return ToUtf8(buffer);
    }


    static bool IsInterestingWindow(HWND hwnd) {
        if (hwnd == nullptr) return false;
        if (!IsWindow(hwnd)) return false;
        if (!IsWindowVisible(hwnd)) return false;
        if (!IsWindowEnabled(hwnd)) return false;

        wchar_t className[256] = { 0 };
        if (GetClassNameW(hwnd, className, static_cast<int>(_countof(className)))) {
            std::wstring cls(className);

            if (cls == L"Shell_TrayWnd" || cls == L"Shell_SecondaryTrayWnd" || cls == L"Progman") {
                return false;
            }
        }


        return true;
    }

    static HWINEVENTHOOK s_hook = nullptr;
    static HWND s_selfWindow = nullptr;
    static HWND s_prevForegroundWin = nullptr;
    static flutter::MethodChannel<flutter::EncodableValue>* s_channel = nullptr;

    void CALLBACK HandleWinEventProc(HWINEVENTHOOK /*hWinEventHook*/, DWORD event, HWND hwnd,
        LONG /*idObject*/, LONG /*idChild*/, DWORD /*dwEventThread*/, DWORD /*dwmsEventTime*/) {
        if (s_channel == nullptr) return;
        if (s_selfWindow == nullptr || hwnd == nullptr) return;
        if (hwnd == s_selfWindow || hwnd == s_prevForegroundWin) return;

        if (event == EVENT_SYSTEM_FOREGROUND) {

            if (!IsInterestingWindow(hwnd)) return;

            std::string title = GetWindowTitle(hwnd);
            // exclude empty title HWND
            if (title.empty()) return;

            s_prevForegroundWin = hwnd;

            flutter::EncodableMap args;
            args[flutter::EncodableValue("name")] = flutter::EncodableValue(title);
            s_channel->InvokeMethod("prev_actived_window",
                std::make_unique<flutter::EncodableValue>(args));
        }
    }

}  // namespace

PrevFocusWindow::PrevFocusWindow(flutter::MethodChannel<flutter::EncodableValue>* channel, HWND hwnd)
    : CommonFeaturesInterface(channel) {
    s_channel = channel;
    s_selfWindow = hwnd;

    s_hook = SetWinEventHook(
        EVENT_SYSTEM_FOREGROUND,
        EVENT_SYSTEM_FOREGROUND,
        NULL,
        HandleWinEventProc,
        0, 0,
        WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS);
}

PrevFocusWindow::~PrevFocusWindow() {
    if (s_hook != nullptr) {
        UnhookWinEvent(s_hook);
        s_hook = nullptr;
    }
    s_channel = nullptr;
    s_selfWindow = nullptr;
    s_prevForegroundWin = nullptr;
}

std::vector<std::string> PrevFocusWindow::Methods() const {
    return { "activate_prev_window" };
}

flutter::MethodChannel<flutter::EncodableValue>* PrevFocusWindow::Channel() const {
    return channel_;
}

void PrevFocusWindow::Handle(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const std::string method = call.method_name();

    if (method == "activate_prev_window") {
        if (s_prevForegroundWin != nullptr) {
            if (SetForegroundWindow(s_prevForegroundWin)) {
                result->Success(flutter::EncodableValue(true));
                return;
            }
            s_prevForegroundWin = nullptr;
        }
        result->Success(flutter::EncodableValue(false));
        return;
    }

    result->NotImplemented();
}