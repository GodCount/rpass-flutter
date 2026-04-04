#ifndef FLUTTER_PLUGIN_PREV_FOCUS_WINDOW_H_
#define FLUTTER_PLUGIN_PREV_FOCUS_WINDOW_H_

#include "../common_features_interface.h"

#include <flutter/encodable_value.h>
#include <memory>
#include <string>
#include <vector>

class PrevFocusWindow : public CommonFeaturesInterface {
public:
	explicit PrevFocusWindow(flutter::MethodChannel<flutter::EncodableValue>* channel, HWND hwnd);
	~PrevFocusWindow() override;

	std::vector<std::string> Methods() const override;
	flutter::MethodChannel<flutter::EncodableValue>* Channel() const override;

	void Handle(
		const flutter::MethodCall<flutter::EncodableValue>& call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) override;
};
#endif  // FLUTTER_PLUGIN_PREV_FOCUS_WINDOW_H_