#include "native_channel.h"


void RegisterMethodHandler(flutter::FlutterEngine* registry) {
    flutter::MethodChannel<> channel(
        registry->messenger(), "native_channel_rpass",
        &flutter::StandardMethodCodec::GetInstance());
    channel.SetMethodCallHandler(
            [](const flutter::MethodCall<>& call,
               std::unique_ptr<flutter::MethodResult<>> result) {
                std::string method_name = call.method_name();
            });
}