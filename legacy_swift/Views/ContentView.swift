import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MagicViewModel()
    
    var body: some View {
        ZStack {
            // Background Layer
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Content Layer based on State
            Group {
                switch viewModel.currentState {
                case .idle:
                    if let image = viewModel.desktopImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture(count: 3) {
                                viewModel.tripleTapTriggered()
                            }
                    } else {
                        // Fallback: Black background with hidden hint
                        Color.black
                            .edgesIgnoringSafeArea(.all)
                            .overlay(
                                Text("No Desktop Image") // Debug hint
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.3))
                                    .padding(.top, 50),
                                alignment: .top
                            )
                            .onTapGesture(count: 3) {
                                viewModel.tripleTapTriggered()
                            }
                    }
                        
                case .appearing, .looping, .changing, .changedLooping, .vanishing:
                    // Video Player Area
                   VideoContainerView(viewModel: viewModel)
                        
                case .ended:
                     // Mock Exit: Show Desktop Image again to look like we quit
                    if let image = viewModel.desktopImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture(count: 2) {
                                // Secret reset
                                viewModel.reset()
                            }
                    } else {
                        Color.black
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture(count: 2) {
                                viewModel.reset()
                            }
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all) // Ensure full screen including status bar area
    }
}

// Subview for video container to keep main view clean
struct VideoContainerView: View {
    @ObservedObject var viewModel: MagicViewModel
    
    var body: some View {
        ZStack {
            if let player = viewModel.videoManager.player {
                VideoPlayerView(player: player)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.black // Fallback
            }
            
            // Debug Overlay layer - Remove in production or toggle
            VStack {
                Spacer()
                Text("State: \(String(describing: viewModel.currentState))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 20)
                
                if viewModel.currentState == .looping {
                    Text("Long Press to transform")
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(5)
                        .padding(.bottom, 50)
                }
                
                if viewModel.currentState == .changedLooping {
                    Text("Blow into mic to vanish")
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(5)
                        .padding(.bottom, 50)
                        
                        // Note: actual blow detection start call should probably be in VM state change
                        // or a view modifier like .onAppear
                }
            }
        }
        // Interaction Gestures
        .onLongPressGesture(minimumDuration: 1.0) {
            viewModel.longPressTriggered()
        }
        // Blow detection is continuous, handled by VM/AudioService
    }
}
