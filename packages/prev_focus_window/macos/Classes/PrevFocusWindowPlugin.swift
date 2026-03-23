import Cocoa
import FlutterMacOS

extension NSRunningApplication {
    var isCurrentApplication: Bool {
        return self.processIdentifier == ProcessInfo.processInfo.processIdentifier
    }
}

public class PrevFocusWindowPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "prev_focus_window", binaryMessenger: registrar.messenger)
        let instance = PrevFocusWindowPlugin(registrar, channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private var registrar: FlutterPluginRegistrar!
    private var channel: FlutterMethodChannel!
    private var prevActivedApplication: NSRunningApplication? = nil

    public init(_ registrar: FlutterPluginRegistrar, _ channel: FlutterMethodChannel) {
        super.init()
        self.registrar = registrar
        self.channel = channel

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate(notification:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc func applicationDidActivate(notification: Notification) {
        if let userInfo = notification.userInfo,
            let application = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        {
            if !application.isCurrentApplication {
                self.prevActivedApplication = application
                let args = [
                    "name": application.localizedName
                ]
                self.channel.invokeMethod("prev_actived_window", arguments: args)
            }
        } else {
            self.prevActivedApplication = nil
            self.channel.invokeMethod("prev_actived_window", arguments: ["name": nil])
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let methodName: String = call.method
        switch methodName {
        case "activate_prev_window":
            if let application = self.prevActivedApplication {
                if application.isActive {
                    return result(true)
                } else if !application.isTerminated {
                    return result(application.activate(options: .activateAllWindows))
                }
            }
            self.prevActivedApplication = nil
            result(false)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }

}
