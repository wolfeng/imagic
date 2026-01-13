import SwiftUI
import AVFoundation

struct VideoPlayerView: UIViewRepresentable {
    var player: AVQueuePlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        return PlayerUIView(player: player)
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.player != player {
            uiView.player = player
        }
    }
}

class PlayerUIView: UIView {
    var player: AVQueuePlayer? {
        get { (layer as? AVPlayerLayer)?.player as? AVQueuePlayer }
        set { (layer as? AVPlayerLayer)?.player = newValue }
    }
    
    init(player: AVQueuePlayer) {
        super.init(frame: .zero)
        let playerLayer = self.layer as! AVPlayerLayer
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = UIColor.black.cgColor // Default black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
