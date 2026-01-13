import SwiftUI
import AVFoundation
import Combine

enum MagicState {
    case idle           // 桌面伪装截图
    case appearing      // 视频1：出现（非循环）
    case looping        // 视频2：美女持牌循环
    case changing       // 视频3：红心消失（非循环）
    case changedLooping // 视频4：美女持无心牌循环
    case vanishing      // 视频5：美女消散（非循环）
    case ended          // 结束（黑屏/伪装）
}

class MagicViewModel: ObservableObject {
    @Published var currentState: MagicState = .idle
    @Published var videoManager = VideoManager()
    @Published var desktopImage: UIImage?
    
    private var audioManager = AudioInputManager()
    
    // Video filenames - Constants for now, can be made dynamic later
    private let videoAppearing = "appearing"
    private let videoLooping = "looping"
    private let videoChanging = "changing"
    private let videoChangedLooping = "changed_looping"
    private let videoVanishing = "vanishing"
    
    init() {
        print("MagicViewModel initialized")
        preloadVideos()
        setupAudio()
        loadDesktopImage()
    }
    
    private func loadDesktopImage() {
        if let image = UIImage(named: "desktop.png") {
            self.desktopImage = image
        } else {
            // Fallback strategy: check documents directory or specific path
            // For now, just print logic
            print("No desktop.png found in bundle.")
        }
    }
    
    private func setupAudio() {
        audioManager.onBlowDetected = { [weak self] in
            DispatchQueue.main.async {
                self?.blowDetected()
            }
        }
    }
    
    private func preloadVideos() {
        // Preload video items to ensure smooth playback
        _ = videoManager.loadVideo(named: videoAppearing)
        _ = videoManager.loadVideo(named: videoLooping)
        _ = videoManager.loadVideo(named: videoChanging)
        _ = videoManager.loadVideo(named: videoChangedLooping)
        _ = videoManager.loadVideo(named: videoVanishing)
    }
    
    func tripleTapTriggered() {
        guard currentState == .idle else { return }
        print("Triple tap detected -> Transitioning to Appearing")
        currentState = .appearing
        
        guard let item = videoManager.loadVideo(named: videoAppearing) else {
            print("Failed to load appearing video, skipping to looping for debug")
            self.currentState = .looping
            return
        }
        
        videoManager.playOnce(item: item) { [weak self] in
            // When appearing finishes, auto transition to looping
            self?.startLoopingState()
        }
    }
    
    private func startLoopingState() {
        print("Transitioning to Looping")
        currentState = .looping
        guard let item = videoManager.loadVideo(named: videoLooping) else { return }
        videoManager.playLoop(item: item)
    }
    
    func longPressTriggered() {
        guard currentState == .looping else { return }
        print("Long press detected -> Transitioning to Changing")
        currentState = .changing
        
        guard let item = videoManager.loadVideo(named: videoChanging) else { return }
        videoManager.playOnce(item: item) { [weak self] in
            self?.startChangedLoopingState()
        }
    }
    
    private func startChangedLoopingState() {
        print("Transitioning to Changed Looping")
        currentState = .changedLooping
        guard let item = videoManager.loadVideo(named: videoChangedLooping) else { return }
        videoManager.playLoop(item: item)
        
        // Start listening for blow
        audioManager.startMonitoring()
    }
    
    func blowDetected() {
        guard currentState == .changedLooping else { return }
        print("Blow detected -> Transitioning to Vanishing")
        
        // Stop listening
        audioManager.stopMonitoring()
        
        currentState = .vanishing
        
        guard let item = videoManager.loadVideo(named: videoVanishing) else { return }
        videoManager.playOnce(item: item) { [weak self] in
            self?.endMagic_()
        }
    }
    
    private func endMagic_() {
        print("Magic Ended")
        currentState = .ended
        videoManager.pause()
        audioManager.stopMonitoring() // Safety check
    }
    
    func reset() {
        currentState = .idle
        videoManager.pause()
        audioManager.stopMonitoring()
    }
}
