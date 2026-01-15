#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  unsigned int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr)
    -1; // remove the trailing null character
  int input_length = (int)wcslen(utf16_string);
  std::string utf8_string;
  if (target_length == 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}



// Scale helper to convert logical scaler values to physical using passed in
// scale factor
int Scale(int source, double scale_factor) {
    return static_cast<int>(source * scale_factor);
}

double ScaleFactor(int x, int y) {
    const POINT target_point = { static_cast<LONG>(x),
                            static_cast<LONG>(y) };
    HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
    UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
    return dpi / 96.0;
}


// Convert wstring into utf8 string
std::string toUtf8(const std::wstring& str) {
    std::string ret;
    int len = WideCharToMultiByte(CP_UTF8, 0, str.c_str(), static_cast<int>(str.length()), NULL, 0, NULL, NULL);
    if (len > 0) {
        ret.resize(len);
        WideCharToMultiByte(CP_UTF8, 0, str.c_str(), static_cast<int>(str.length()), &ret[0], len, NULL, NULL);
    }

    return ret;
}

// Return window title in utf8 string
std::string getWindowTitle(const HWND hwnd) {
    int  bufsize = static_cast<int>(GetWindowTextLengthW(hwnd)) + 1;
    LPWSTR t = new WCHAR[bufsize];
    GetWindowTextW(hwnd, t, bufsize);

    std::wstring ws(t);
    std::string title = toUtf8(ws);

    return title;
}

