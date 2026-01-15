import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSPanel {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let registrar = flutterViewController.registrar(forPlugin: "ExamplePlugin")
    setMethodHandler(registrar: registrar)

    RegisterGeneratedPlugins(registry: flutterViewController)

    NSApplication.shared.setActivationPolicy(.accessory)

    self.styleMask = [
      .titled, .fullSizeContentView, .nonactivatingPanel, .utilityWindow, .hudWindow,
    ]
    self.titlebarAppearsTransparent = true
    self.isMovableByWindowBackground = false
    self.animationBehavior = .none
    self.isFloatingPanel = true
    self.level = .floating
    self.collectionBehavior = [.fullScreenAuxiliary, .ignoresCycle, .moveToActiveSpace]
    super.awakeFromNib()
  }

  public func setMethodHandler(registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.example", binaryMessenger: registrar.messenger)

    var activeApp: NSRunningApplication? = nil
    channel.setMethodCallHandler({
      (call, result) -> Void in
      print("setMethodCallHandler", call.method)
      switch call.method {
      case "recordTopWindow":
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
          if app.isActive {
            activeApp = app
            break
          }
        }
        result(activeApp?.localizedName)
        break
      case "setTopWindow":
        result(activeApp?.activate(options: .activateAllWindows) ?? false)
        activeApp = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    })
  }
}
