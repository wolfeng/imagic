
import SwiftUI
import AVKit
import Combine

// MARK: - MagicView

struct MagicView: View {
    @ObservedObject var engine: MagicEngine
    
    var body: some View {
        ZStack {
            if let stage = engine.currentStage {
                // Media
                Group {
                    if stage.type == .video {
                        VideoPlayerView(source: stage.source, mode: stage.mode) {
                            engine.onVideoFinished()
                        }
                    } else {
                        AsyncImage(url: URL(fileURLWithPath: stage.source)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.black
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                // Overlay
                if stage.showTime {
                    VStack {
                        HStack {
                            TimeOverlay()
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding()
                }
            } else {
                Text("No Stage Loaded").foregroundColor(.white)
            }
        }
    }
}

// MARK: - Video Helper

struct VideoPlayerView: UIViewControllerRepresentable {
    let source: String
    let mode: PlaybackMode
    let onFinish: () -> Void
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        let url = URL(fileURLWithPath: source)
        
        if uiViewController.player == nil || (uiViewController.player?.currentItem?.asset as? AVURLAsset)?.url != url {
            let player = AVPlayer(url: url)
            uiViewController.player = player
            player.play()
            
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                if mode == .loop {
                    player.seek(to: .zero)
                    player.play()
                } else {
                    onFinish()
                }
            }
        }
    }
}

struct TimeOverlay: View {
    @State private var timeString = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(timeString)
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .foregroundColor(.white.opacity(0.8))
            .onReceive(timer) { input in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                timeString = formatter.string(from: input)
            }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var engine = MagicEngine()
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Render Stage
            MagicView(engine: engine)
            
            // Gestures Layer
            GestureView(engine: engine, onSwipeUp: {
                showSettings = true
            })
        }
        .statusBar(hidden: true)
        .sheet(isPresented: $showSettings) {
            SettingsView(engine: engine)
        }
    }
}

struct GestureView: UIViewRepresentable {
    var engine: MagicEngine
    var onSwipeUp: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // Tap
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        
        // Long Press
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleLongPress(_:)))
        view.addGestureRecognizer(longPress)
        
        // Swipe Up
        let swipe = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleSwipe(_:)))
        swipe.direction = .up
        swipe.numberOfTouchesRequired = 1
        view.addGestureRecognizer(swipe)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: GestureView
        var tapCount = 0
        var lastTapTime: TimeInterval = 0
        
        init(_ parent: GestureView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let now = Date().timeIntervalSince1970
            if now - lastTapTime < 0.4 {
                tapCount += 1
            } else {
                tapCount = 1
            }
            lastTapTime = now
            
            // Pass to engine
            parent.engine.onTap(count: tapCount)
            
            if tapCount >= 3 { tapCount = 0 }
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                parent.engine.onLongPress()
            }
        }
        
        @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            parent.onSwipeUp()
        }
    }
}
