import SwiftUI

struct ContentView: View {
    @Environment(OrchORSimulation.self) private var sim
    @State private var tab = UserDefaults.standard.integer(forKey: "tab")

    var body: some View {
        TabView(selection: $tab) {
            MicrotubuleView().tabItem { Label("Microtubule", systemImage: "cylinder") }.tag(0)
            TimelineView().tabItem { Label("Timeline", systemImage: "waveform.path.ecg") }.tag(1)
            CalculatorView().tabItem { Label("Calculator", systemImage: "function") }.tag(2)
            LearnView().tabItem { Label("Learn", systemImage: "book") }.tag(3)
        }
        .tint(Theme.teal)
        .task {
            // Drive the simulation at ~30 fps while the app is in the foreground.
            var last = Date()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                let now = Date()
                sim.tick(realDt: min(0.1, now.timeIntervalSince(last)))
                last = now
            }
        }
    }
}
