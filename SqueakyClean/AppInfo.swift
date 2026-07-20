import Foundation

enum AppInfo {
    static var displayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Squeaky Clean"
    }
}
