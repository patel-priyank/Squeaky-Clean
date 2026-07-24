import Sparkle
import SwiftUI

@main
struct SqueakyCleanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Window") { }
                    .disabled(true)
            }
            CommandGroup(replacing: .appInfo) {
                Button("About \(AppInfo.displayName)") {
                    showAboutPanel()
                }
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    appDelegate.updaterController.checkForUpdates(nil)
                }
            }
        }
    }
}

func showAboutPanel() {
    let paragraphStyle = NSMutableParagraphStyle()
    
    paragraphStyle.alignment = .center
    
    let baseAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 11),
        .foregroundColor: NSColor.secondaryLabelColor,
        .paragraphStyle: paragraphStyle
    ]
    
    let credits = NSMutableAttributedString(
        string: "App icon and illustrations from Flaticon\n\n",
        attributes: baseAttributes
    )
    
    let sources: [(label: String, urlString: String)] = [
        ("Cheerful stickers", "https://www.flaticon.com/free-stickers/cheerful"),
        ("Cute stickers", "https://www.flaticon.com/free-stickers/cute"),
        ("Dislike stickers", "https://www.flaticon.com/free-stickers/dislike")
    ]
    
    for (index, source) in sources.enumerated() {
        var linkAttributes = baseAttributes
        linkAttributes[.link] = URL(string: source.urlString)
        linkAttributes[.foregroundColor] = NSColor.linkColor
        
        credits.append(NSAttributedString(string: source.label, attributes: linkAttributes))
        
        if index < sources.count - 1 {
            credits.append(NSAttributedString(string: "\n", attributes: baseAttributes))
        }
    }
    
    NSApp.orderFrontStandardAboutPanel(options: [
        .applicationName: AppInfo.displayName,
        .credits: credits
    ])
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "autoEnableCleaningMode") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                CleaningModeManager.shared.startCleaningMode()
            }
        }
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        CleaningModeManager.shared.stopCleaningMode()
    }
}
