import SwiftUI

@main
struct OrchORApp: App {
    @State private var sim = OrchORSimulation()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sim)
                .preferredColorScheme(.light)
                #if DEBUG
                .onAppear { sim.stageIfRequested() }
                #endif
        }
    }
}
