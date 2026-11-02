import SwiftUI

@main
struct OrchORApp: App {
    @State private var sim = OrchORSimulation()
    @State private var tips = TipJarStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sim)
                .environment(tips)
                .task { tips.start() }
                .preferredColorScheme(.light)
                #if DEBUG
                .onAppear { sim.stageIfRequested() }
                #endif
        }
    }
}
