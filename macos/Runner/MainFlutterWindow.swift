import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Content runs under a transparent title bar. An empty unified toolbar
    // makes the title bar taller, which moves the window buttons down and in,
    // so they sit inside the sidebar instead of on its edge.
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    let toolbar = NSToolbar(identifier: "MainToolbar")
    toolbar.showsBaselineSeparator = false
    self.toolbar = toolbar
    self.toolbarStyle = .unified

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
