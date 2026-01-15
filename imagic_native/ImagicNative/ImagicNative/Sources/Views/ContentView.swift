
import SwiftUI
import AVKit
import Combine

// MARK: - MagicView

struct MagicView: View {
    @ObservedObject var engine: MagicEngine
    
    // Manage a stack of active stages for seamless transitions
    @State private var activeStages: [MagicStage] = []
    
    var body: some View {
        ZStack {
            ForEach(activeStages) { stage in
                Group {
                    if stage.type == .video {
                        VideoPlayerView(source: stage.source, mode: stage.mode, onFinish: {
                            engine.onVideoFinished()
                        }, onReady: {
                            handleStageReady(stage)
                        })
                    } else {
                        SmartImageView(source: stage.source) {
                            handleStageReady(stage)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .zIndex(blockZIndex(for: stage))
                
                // Overlay (Time)
                if stage.showTime {
                    VStack {
                        HStack {
                            TimeOverlay()
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding()
                    .zIndex(blockZIndex(for: stage) + 0.1)
                }
            }
            
            if activeStages.isEmpty {
                Text(Localization.get("No Stage Loaded", for: engine.config.language)).foregroundColor(.white)
            }
        }
        .onAppear {
            if let startStage = engine.currentStage {
                activeStages = [startStage]
            }
        }
        .onReceive(engine.$currentStage) { newStage in
            guard let newStage = newStage else { 
                // typically this means reset
                activeStages.removeAll()
                return 
            }
            
            if let last = activeStages.last {
                if last.id != newStage.id {
                    // New stage transition -> Append
                    activeStages.append(newStage)
                } else {
                    // Same stage ID (likely edited/reloaded) -> Replace to force update
                    // We remove the last one and append the new version
                    activeStages.removeLast()
                    activeStages.append(newStage)
                }
            } else {
                activeStages.append(newStage)
            }
        }
    }
    
    func blockZIndex(for stage: MagicStage) -> Double {
        return Double(activeStages.firstIndex(where: { $0.id == stage.id }) ?? 0)
    }
    
    func handleStageReady(_ stage: MagicStage) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                if let index = activeStages.firstIndex(where: { $0.id == stage.id }) {
                    if index > 0 {
                        activeStages.removeSubrange(0..<index)
                    }
                }
            }
        }
    }
}

// MARK: - Image Helper

struct SmartImageView: View {
    let source: String
    let onReady: () -> Void
    
    var body: some View {
        AsyncImage(url: URL(fileURLWithPath: source)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
                    .onAppear {
                        DispatchQueue.main.async { onReady() }
                    }
            case .failure:
                 Color.black
            case .empty:
                 Color.clear
            @unknown default:
                 Color.clear
            }
        }
    }
}

// MARK: - Video Helper

class DualPlayerUIView: UIView {
    let playerLayer1 = AVPlayerLayer()
    let playerLayer2 = AVPlayerLayer()
    var activeLayer: AVPlayerLayer
    
    override init(frame: CGRect) {
        activeLayer = playerLayer1
        super.init(frame: frame)
        setupLayer(playerLayer1)
        setupLayer(playerLayer2)
        layer.addSublayer(playerLayer2)
        layer.addSublayer(playerLayer1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayer(_ l: AVPlayerLayer) {
        l.videoGravity = .resizeAspectFill
        l.backgroundColor = UIColor.clear.cgColor
        l.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer1.frame = bounds
        playerLayer2.frame = bounds
    }
    
    func swapLayers() {
        let inactive = (activeLayer == playerLayer1) ? playerLayer2 : playerLayer1
        inactive.isHidden = false
        layer.insertSublayer(inactive, above: activeLayer)
        activeLayer.player?.pause()
        activeLayer.player = nil
        activeLayer = inactive
    }
    
    func getInactiveLayer() -> AVPlayerLayer {
        return (activeLayer == playerLayer1) ? playerLayer2 : playerLayer1
    }
}

struct VideoPlayerView: UIViewRepresentable {
    let source: String
    let mode: PlaybackMode
    let onFinish: () -> Void
    let onReady: (() -> Void)?
    
    init(source: String, mode: PlaybackMode, onFinish: @escaping () -> Void, onReady: (() -> Void)? = nil) {
        self.source = source
        self.mode = mode
        self.onFinish = onFinish
        self.onReady = onReady
    }
    
    func makeUIView(context: Context) -> DualPlayerUIView {
        let view = DualPlayerUIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: DualPlayerUIView, context: Context) {
        let url = URL(fileURLWithPath: source)
        
        if let currentPlayer = uiView.activeLayer.player,
           let currentAsset = currentPlayer.currentItem?.asset as? AVURLAsset,
           currentAsset.url == url {
            return
        }
        
        let inactiveLayer = uiView.getInactiveLayer()
        let player = AVPlayer(url: url)
        player.actionAtItemEnd = .none
        inactiveLayer.player = player
        
        context.coordinator.prepareTransition(to: player, on: inactiveLayer, in: uiView, mode: mode)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: VideoPlayerView
        var timeObserver: NSObjectProtocol?
        var layerObserver: NSKeyValueObservation?
        
        init(_ parent: VideoPlayerView) {
            self.parent = parent
        }
        
        func prepareTransition(to player: AVPlayer, on layer: AVPlayerLayer, in view: DualPlayerUIView, mode: PlaybackMode) {
            player.play()
            layerObserver?.invalidate()
            layerObserver = layer.observe(\.isReadyForDisplay, options: [.new]) { [weak self, weak view, weak layer] _, _ in
                guard let self = self, let view = view, let layer = layer else { return }
                if layer.isReadyForDisplay {
                    DispatchQueue.main.async {
                        view.swapLayers()
                        self.setupEndObserver(for: player, mode: mode)
                        self.parent.onReady?()
                        self.layerObserver?.invalidate()
                        self.layerObserver = nil
                    }
                }
            }
        }
        
        func setupEndObserver(for player: AVPlayer, mode: PlaybackMode) {
            if let observer = timeObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            guard let item = player.currentItem else { return }
            timeObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self, weak player] _ in
                guard let self = self, let player = player else { return }
                if mode == .loop {
                    player.seek(to: .zero)
                    player.play()
                } else {
                    self.parent.onFinish()
                }
            }
        }
        
        deinit {
            if let observer = timeObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            layerObserver?.invalidate()
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
        
        // Swipe Up (4 fingers for hidden settings)
        let swipe = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleSwipe(_:)))
        swipe.direction = .up
        swipe.numberOfTouchesRequired = 4
        view.addGestureRecognizer(swipe)
        
        // Pan (for Circle)
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        
        // Removed require(toFail: swipe) to improve responsiveness
        
        swipe.delegate = context.coordinator
        pan.delegate = context.coordinator
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: GestureView
        var tapCount = 0
        var lastTapTime: TimeInterval = 0
        var points: [CGPoint] = []
        
        init(_ parent: GestureView) {
            self.parent = parent
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let now = Date().timeIntervalSince1970
            if now - lastTapTime < 0.4 {
                tapCount += 1
            } else {
                tapCount = 1
            }
            lastTapTime = now
            
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
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            
            switch gesture.state {
            case .began:
                points = [location]
            case .changed:
                points.append(location)
            case .ended:
                if isCircle(points) {
                    print("Circle Detected!")
                    parent.engine.onCircle()
                }
                points = []
            case .cancelled, .failed:
                points = []
            default:
                break
            }
        }
        
        func isCircle(_ points: [CGPoint]) -> Bool {
            guard points.count > 10 else { return false }
            
            let minX = points.map { $0.x }.min() ?? 0
            let maxX = points.map { $0.x }.max() ?? 0
            let minY = points.map { $0.y }.min() ?? 0
            let maxY = points.map { $0.y }.max() ?? 0
            
            let width = maxX - minX
            let height = maxY - minY
            
            // Relaxed aspect ratio
            let ratio = width / height
            if ratio < 0.5 || ratio > 2.0 { return false }
            
            if width < 50 || height < 50 { return false }
            
            let start = points.first!
            let end = points.last!
            let distance = hypot(start.x - end.x, start.y - end.y)
            
            // Relaxed closure threshold
            let threshold = (width + height) / 2 * 0.5
            
            return distance < threshold
        }
    }
}
