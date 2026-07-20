import AppKit
import Combine
import CoreGraphics
import Foundation

final class CleaningModeManager: ObservableObject {
    static let shared = CleaningModeManager()
    
    @Published var accessibilityGranted = false
    @Published var holdProgress: Double = 0
    @Published var isActive = false
    @Published var isHolding = false
    
    private let holdDuration: TimeInterval = 3.0
    private let completionPause: TimeInterval = 0.25
    private let crossfadeDuration: TimeInterval = 0.25
    private let leadTime: TimeInterval = 0.25
    private let stepCount = 3
    
    private var awaitingKeyUpTeardown = false
    private var cancellables = Set<AnyCancellable>()
    private var eventTap: CFMachPort?
    private var holdStartTime: Date?
    private var holdTimer: Timer?
    private var isCompleting = false
    private var isSpacebarCurrentlyDown = false
    private var runLoopSource: CFRunLoopSource?
    private var shouldLockMouseAndTrackpad = true
    
    private init() {
        refreshAccessibilityStatus()
        
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshAccessibilityStatus()
            }
            .store(in: &cancellables)
    }
    
    func refreshAccessibilityStatus() {
        accessibilityGranted = AXIsProcessTrusted()
    }
    
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
    
    func startCleaningMode() {
        guard accessibilityGranted else {
            requestAccessibilityPermission()
            return
        }
        
        holdProgress = 0
        isCompleting = false
        isHolding = false
        
        shouldLockMouseAndTrackpad = UserDefaults.standard.bool(forKey: "lockTrackpadAndMouse")
        
        guard startEventTap() else {
            refreshAccessibilityStatus()
            return
        }
        
        isActive = true
    }
    
    func stopCleaningMode() {
        holdTimer?.invalidate()
        
        holdTimer = nil
        holdStartTime = nil
        holdProgress = 0
        isActive = false
        isCompleting = false
        isHolding = false
        
        finishTeardown()
    }
    
    func spacebarKeyDown() {
        isSpacebarCurrentlyDown = true
        
        guard isActive, holdTimer == nil, !isCompleting else { return }
        
        holdProgress = 0
        holdStartTime = Date()
        isHolding = true
        
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        RunLoop.current.add(timer, forMode: .common)
        
        holdTimer = timer
    }
    
    func spacebarKeyUp() {
        holdTimer?.invalidate()
        
        holdTimer = nil
        holdStartTime = nil
        isSpacebarCurrentlyDown = false
        
        if isActive && !isCompleting {
            holdProgress = 0
            isHolding = false
        }
        
        if awaitingKeyUpTeardown {
            awaitingKeyUpTeardown = false
            stopEventTap()
        }
    }
    
    private func tick() {
        guard let start = holdStartTime else { return }
        
        let effectiveDuration = holdDuration - leadTime
        let elapsed = Date().timeIntervalSince(start)
        let stepDuration = effectiveDuration / Double(stepCount)
        
        let completedSteps = min(Int(elapsed / stepDuration), stepCount)
        
        holdProgress = Double(completedSteps) / Double(stepCount)
        
        if elapsed >= holdDuration {
            holdTimer?.invalidate()
            
            holdTimer = nil
            isCompleting = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + completionPause) { [weak self] in
                self?.finishUnlock()
            }
        }
    }
    
    private func finishUnlock() {
        holdStartTime = nil
        isActive = false
        isCompleting = false
        isHolding = false
        
        finishTeardown()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + crossfadeDuration) { [weak self] in
            self?.holdProgress = 0
        }
    }
    
    private func finishTeardown() {
        if isSpacebarCurrentlyDown {
            awaitingKeyUpTeardown = true
        } else {
            stopEventTap()
        }
    }
    
    @discardableResult
    private func startEventTap() -> Bool {
        guard eventTap == nil else { return true }
        
        var mask: CGEventMask = 0
        
        mask |= 1 << CGEventType.keyDown.rawValue
        mask |= 1 << CGEventType.keyUp.rawValue
        mask |= 1 << CGEventType.flagsChanged.rawValue
        mask |= 1 << CGEventType.leftMouseDown.rawValue
        mask |= 1 << CGEventType.leftMouseUp.rawValue
        mask |= 1 << CGEventType.rightMouseDown.rawValue
        mask |= 1 << CGEventType.rightMouseUp.rawValue
        mask |= 1 << CGEventType.otherMouseDown.rawValue
        mask |= 1 << CGEventType.otherMouseUp.rawValue
        mask |= 1 << CGEventType.mouseMoved.rawValue
        mask |= 1 << CGEventType.leftMouseDragged.rawValue
        mask |= 1 << CGEventType.rightMouseDragged.rawValue
        mask |= 1 << CGEventType.otherMouseDragged.rawValue
        mask |= 1 << CGEventType.scrollWheel.rawValue
        
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: cleaningModeEventTapCallback,
            userInfo: refcon
        ) else {
            return false
        }
        
        eventTap = tap
        
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        
        runLoopSource = source
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        return true
    }
    
    private func stopEventTap() {
        guard let tap = eventTap else { return }
        
        CGEvent.tapEnable(tap: tap, enable: false)
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        
        CFMachPortInvalidate(tap)
        
        eventTap = nil
        runLoopSource = nil
    }
    
    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            guard AXIsProcessTrusted() else {
                DispatchQueue.main.async { [weak self] in
                    self?.forceStopDueToRevokedPermission()
                }
                
                return nil
            }
            
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            
            return nil
        }
        
        switch type {
        case .keyDown, .keyUp:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            
            if keyCode == 49 {
                if type == .keyDown {
                    spacebarKeyDown()
                } else {
                    spacebarKeyUp()
                }
            }
            
            return nil
            
        case .flagsChanged:
            return nil
            
        default:
            return shouldLockMouseAndTrackpad ? nil : Unmanaged.passRetained(event)
        }
    }
    
    private func forceStopDueToRevokedPermission() {
        accessibilityGranted = false
        stopCleaningMode()
    }
}

private func cleaningModeEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
    
    let manager = Unmanaged<CleaningModeManager>.fromOpaque(refcon).takeUnretainedValue()
    
    return manager.handle(type: type, event: event)
}
