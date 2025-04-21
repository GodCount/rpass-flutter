import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // register self method handler
    let registrar = flutterViewController.registrar(forPlugin: "RpassPlugin")
    setMethodHandler(registrar: registrar)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  public func setMethodHandler(registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "native_channel_rpass",
      binaryMessenger: registrar.messenger
    )
    channel.setMethodCallHandler({
      (call, result) -> Void in
      switch call.method {
      default:
        result(FlutterMethodNotImplemented)
      }
    })
  }

}
