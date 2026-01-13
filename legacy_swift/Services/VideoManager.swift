import AVFoundation
import Combine

class VideoManager: ObservableObject {
    @Published var player: AVQueuePlayer?
    
    private var playerLooper: AVPlayerLooper?
    private var items: [String: AVPlayerItem] = [:]
    
    // Tracks if we are currently ensuring a video loops
    private var isLooping: Bool = false
    
    init() {
        // Initialize with a silent player to be ready
        let player = AVQueuePlayer()
        player.isMuted = false
        self.player = player
    }
    
    /// Loads a video from the Bundle (or Documents later) and prepares it
    func loadVideo(named fileName: String, withExtension ext: String = "mp4") -> AVPlayerItem? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            print("Error: Could not find video \(fileName).\(ext)")
            return nil
        }
        let item = AVPlayerItem(url: url)
        items[fileName] = item
        return item
    }
    
    /// Plays a video once, then optionally triggers a completion handler
    func playOnce(item: AVPlayerItem, completion: (() -> Void)? = nil) {
        stopLooping()
        
        guard let player = player else { return }
        
        player.removeAllItems()
        player.insert(item, after: nil)
        player.play()
        
        // simple observer for item end
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
            completion?()
        }
    }
    
    /// Loops a video seamlessly
    func playLoop(item: AVPlayerItem) {
        stopLooping()
        
        guard let player = player else { return }
        player.removeAllItems()
        
        // Create a new looper
        playerLooper = AVPlayerLooper(player: player, templateItem: item)
        player.play()
        isLooping = true
    }
    
    private func stopLooping() {
        if isLooping {
            playerLooper?.disableLooping()
            playerLooper = nil
            isLooping = false
        }
    }
    
    func pause() {
        player?.pause()
    }
    
    func resume() {
        player?.play()
    }
}
