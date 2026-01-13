import SwiftUI

@main
struct ImagicApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .statusBar(hidden: true)
        }
    }
}
