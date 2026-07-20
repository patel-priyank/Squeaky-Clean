import SwiftUI

struct ContentView: View {
    @AppStorage("autoEnableCleaningMode") private var autoEnableCleaningMode = false
    @AppStorage("lockTrackpadAndMouse") private var lockTrackpadAndMouse = true
    
    @ObservedObject private var manager = CleaningModeManager.shared
    
    var body: some View {
        VStack {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(manager.isActive ? "CatThumbsDown" : "CatCelebrate")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .padding(.bottom, 16)
                    
                    Text(AppInfo.displayName)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Locks input so you can wipe your Mac down safely.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading) {
                        settingToggle(icon: "computermouse", title: "Lock trackpad and mouse", isOn: $lockTrackpadAndMouse)
                        
                        Text("Keyboard is always locked while cleaning.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 28)
                    }
                    
                    settingToggle(icon: "power", title: "Auto-start on app launch", isOn: $autoEnableCleaningMode)
                }
                
                ZStack {
                    Group {
                        if #available(macOS 26, *) {
                            Button {
                                guard !manager.isActive else { return }
                                
                                manager.startCleaningMode()
                            } label: {
                                Text("Start cleaning")
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glassProminent)
                        } else {
                            Button {
                                guard !manager.isActive else { return }
                                
                                manager.startCleaningMode()
                            } label: {
                                Text("Start cleaning")
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.extraLarge)
                    .opacity(manager.isActive ? 0 : 1)
                    .scaleEffect(manager.isActive ? 0.95 : 1)
                    .allowsHitTesting(!manager.isActive)
                    
                    VStack(spacing: 6) {
                        ProgressView(value: manager.holdProgress)
                            .progressViewStyle(.linear)
                            .animation(nil, value: manager.holdProgress)
                        
                        Text(manager.isHolding ? "Keep holding..." : "Hold spacebar to unlock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.tint)
                    }
                    .opacity(manager.isActive ? 1 : 0)
                    .scaleEffect(manager.isActive ? 1 : 0.95)
                    .allowsHitTesting(manager.isActive)
                }
                .frame(height: 40)
                .animation(.easeInOut(duration: 0.25), value: manager.isActive)
                
                Text(manager.accessibilityGranted ? "Accessibility permission granted." : "Accessibility permission needed.")
                    .font(.system(size: 11))
                    .foregroundStyle(manager.accessibilityGranted ? .tertiary : .secondary)
            }
            .padding(20)
        }
        .frame(width: 340)
        .background(WindowAccessor())
    }
    
    @ViewBuilder
    private func settingToggle(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Label {
                Text(title).font(.system(size: 14))
            } icon: {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, alignment: .center)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(manager.isActive)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

#Preview {
    ContentView()
}
