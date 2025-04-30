import Cocoa
import FlutterMacOS

extension NSRunningApplication {
    var isCurrentApplication: Bool {
        return self.processIdentifier == ProcessInfo.processInfo.processIdentifier
    }
}

class RpassFultterPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "native_channel_rpass", binaryMessenger: registrar.messenger)
        let instance = RpassFultterPlugin(registrar, channel)
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
                let args: NSDictionary = [
                    "name": application.localizedName ?? "",
                    "bundleId": application.bundleIdentifier ?? "",

                ]
                self.channel.invokeMethod("prev_actived_application", arguments: args)
            }
        } else {
            self.prevActivedApplication = nil
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let methodName: String = call.method
        // let args: [String: Any] = call.arguments as? [String: Any] ?? [:]
        switch methodName {
        case "activate_prev_application":
            result(self.prevActivedApplication?.activate(options: .activateAllWindows) ?? false)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }

}

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = initWindowFrame()
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        // register self method handler
        RpassFultterPlugin.register(with: flutterViewController.registrar(forPlugin: "RpassPlugin"))
        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }

    public func initWindowFrame() -> NSRect {
        self.minSize = NSSize(
            width: CGFloat(413),
            height: CGFloat(640)
        )

        var windowFrame = self.frame

        windowFrame.size.width = CGFloat(900)
        windowFrame.size.height = CGFloat(640)

        return windowFrame
    }

}
