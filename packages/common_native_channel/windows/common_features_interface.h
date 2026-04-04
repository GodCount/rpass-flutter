#ifndef FLUTTER_PLUGIN_COMMON_FEATURES_INTERFACE_H_
#define FLUTTER_PLUGIN_COMMON_FEATURES_INTERFACE_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <string>
#include <vector>

class CommonFeaturesInterface {
public:
    virtual ~CommonFeaturesInterface() = default;

    CommonFeaturesInterface(const CommonFeaturesInterface&) = delete;
    CommonFeaturesInterface& operator=(const CommonFeaturesInterface&) = delete;

    virtual std::vector<std::string> Methods() const = 0;

    virtual flutter::MethodChannel<flutter::EncodableValue>* Channel() const = 0;

    virtual void Handle(
        const flutter::MethodCall<flutter::EncodableValue>& call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) = 0;

protected:
    explicit CommonFeaturesInterface(flutter::MethodChannel<flutter::EncodableValue>* channel)
        : channel_(channel) {}

    flutter::MethodChannel<flutter::EncodableValue>* channel_ = nullptr;
};

#endif  // FLUTTER_PLUGIN_COMMON_FEATURES_INTERFACE_H_
