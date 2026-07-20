import AppKit
import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            if let window = view.window {
                window.styleMask.remove([.resizable, .miniaturizable])
                window.isMovableByWindowBackground = true
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) { }
}
