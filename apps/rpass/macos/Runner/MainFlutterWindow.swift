import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = initWindowFrame()
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

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
