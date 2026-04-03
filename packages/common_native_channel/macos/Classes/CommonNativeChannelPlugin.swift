import Cocoa
import FlutterMacOS

public class CommonNativeChannelPlugin: NSObject, FlutterPlugin {
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "common_native_channel", binaryMessenger: registrar.messenger)
        let instance = CommonNativeChannelPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    
    private var features: [CommonFeaturesInterface]
    
    init(channel:FlutterMethodChannel) {
        self.features = [PrevFocusWindow(channel: channel)]
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let feature = self.features.first(where: { $0.methods.contains(call.method) }) {
            feature.handle(call, result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
        
    }
}
