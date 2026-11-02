import SwiftUI
import SceneKit

/// 3-D microtubule lattice. Each sphere is a tubulin dimer; colour shows its state.
struct MicrotubuleView: View {
    @Environment(OrchORSimulation.self) private var sim
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var scene = MicrotubuleScene()
    @State private var showAbout = false
    @State private var showTipJar = false

    var body: some View {
        @Bindable var sim = sim
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(index: "01", kicker: "Orch-OR lattice", title: "microtubule", accent: Theme.blue) {
                    Button { showAbout = true } label: { Label("About", systemImage: "info") }
                        .buttonStyle(.bauhaus(.outline, compact: true))
                }
                if hSize == .regular {
                    HStack(alignment: .top, spacing: 16) {
                        sceneBlock(height: 780)
                        VStack(spacing: 16) { readouts; controls(sim: $sim) }
                            .frame(width: 420)
                    }
                } else {
                    sceneBlock(height: 380)
                    readouts
                    controls(sim: $sim)
                }
            }
            .pageFrame()
        }
        .background(Theme.ground)
        .sheet(isPresented: $showAbout) { AboutView() }
        .sheet(isPresented: $showTipJar) { TipJarSheet() }
        .onChange(of: sim.simTime) { _, _ in scene.apply(sim) }
        .onChange(of: sim.stagedRevision) { _, _ in scene.apply(sim) }
        .onAppear {
            scene.apply(sim)
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "showAbout") { showAbout = true }
            if UserDefaults.standard.bool(forKey: "showTipJar") { showTipJar = true }
            #endif
        }
    }

    private func sceneBlock(height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            SceneView(scene: scene.scene, pointOfView: scene.camera, options: [.allowsCameraControl])
                .frame(height: height)
                .accessibilityLabel("3D microtubule lattice, \(sim.superposedCount) of \(sim.count) dimers in superposition")
            // Objective-reduction flash: a flat red field, no glow.
            Theme.red.opacity(Double(sim.flash) * 0.08)
                .frame(height: height)
                .allowsHitTesting(false)
            legend.padding(12)
            if sim.flash > 0.05 {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "bolt").font(.footnote.weight(.bold))
                        Text("OBJECTIVE REDUCTION").font(BFont.label(13, relativeTo: .footnote)).tracking(1.6)
                    }
                    .foregroundStyle(Theme.ground)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Theme.red)
                    .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.rule))
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(height: height)
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.rule))
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            KeyRow(glyph: "arrow.up", color: Theme.stateA, text: "Tubulin state A")
            KeyRow(glyph: "arrow.down", color: Theme.stateB, text: "Tubulin state B")
            KeyRow(glyph: "arrow.up.arrow.down", color: Theme.yellow, text: "Superposition")
            KeyRow(glyph: "bolt", color: Theme.red, text: "Objective reduction")
        }
        .padding(10)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .background(Theme.ground.opacity(0.92))
        .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.rule))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Key: black, state A; grey, state B; yellow, superposition; red, objective reduction")
    }

    private var readouts: some View {
        VStack(alignment: .leading, spacing: 14) {
            ReadoutRow {
                Readout(label: "Superposed", value: "\(sim.superposedCount)/\(sim.count)", marker: Theme.yellow)
                Readout(label: "Represents", value: sim.effectiveTubulins.compact)
                Readout(label: "E_G", value: sim.gravitationalSelfEnergy.sci("J", digits: 1))
            }
            HRule()
            ReadoutRow {
                Readout(label: "τ = ħ/E_G", value: sim.tau.timeString, marker: Theme.yellow)
                Readout(label: "OR events", value: "\(sim.events.count)")
                Readout(label: "Event rate", value: sim.eventFrequencyHz.map { String(format: "%.0f Hz", $0) } ?? "—", marker: Theme.red)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    TrackedText("∫E_G dt → ħ", color: Theme.ink)
                    Spacer()
                    Text(String(format: "%.0f%%", sim.progressToCollapse * 100))
                        .font(BFont.number(15, relativeTo: .footnote))
                        .foregroundStyle(Theme.ink)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Theme.soft
                        (sim.progressToCollapse >= 0.999 || sim.flash > 0.05 ? Theme.red : Theme.yellow)
                            .frame(width: geo.size.width * sim.progressToCollapse)
                    }
                }
                .frame(height: 16)
                .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.rule))
                .accessibilityElement()
                .accessibilityLabel("Progress to collapse")
                .accessibilityValue(String(format: "%.0f percent", sim.progressToCollapse * 100))
                Note("Superposition grows by orchestration, gravitational self-energy accumulates, and at ħ the set self-collapses: one 'moment'. Simulation runs \(Int(sim.slowMotion))× slower than real time.")
            }
        }
        .panel(accent: Theme.yellow)
    }

    private func controls(sim: Bindable<OrchORSimulation>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Button { self.sim.running.toggle() } label: {
                    Label(self.sim.running ? "Pause" : "Run", systemImage: self.sim.running ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.bauhaus(.filled(Theme.blue)))
                Button { self.sim.reset() } label: { Label("Reset", systemImage: "arrow.counterclockwise") }
                    .buttonStyle(.bauhaus(.outline))
                Spacer(minLength: 0)
            }
            BauhausSlider(label: "Orchestration (MAP coupling)", value: sim.orchestration, range: 0 ... 1, accent: Theme.yellow) { String(format: "%.2f", $0) }
            BauhausSlider(label: "Each displayed dimer stands for", value: sim.representationExponent, range: 5 ... 9, accent: Theme.blue) { pow(10, $0).sci("", digits: 1) }
            BauhausSlider(label: "Slow motion", value: sim.slowMotion, range: 1 ... 200, accent: Theme.ink) { "\(Int($0))×" }
            HRule()
            Toggle(isOn: sim.decoherenceEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    TrackedText("Environmental decoherence", color: Theme.ink)
                    Note("Off = Orch-OR's assumption that microtubules are shielded")
                }
            }
            .toggleStyle(BauhausToggleStyle(accent: Theme.red))
            if self.sim.decoherenceEnabled {
                BauhausSlider(label: "Decoherence time", value: sim.decoherenceExponent, range: -13 ... 0, accent: Theme.red) { pow(10, $0).timeString }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { presetButtons }
                    VStack(alignment: .leading, spacing: 10) { presetButtons }
                }
            }
        }
        .panel(accent: Theme.blue)
    }

    @ViewBuilder private var presetButtons: some View {
        Button { self.sim.decoherenceExponent = -13 } label: { Text(Theme.caps("Tegmark 2000 – ") + "10⁻¹³ s").textCase(nil) }
            .buttonStyle(.bauhaus(.outline, compact: true))
        Button { self.sim.decoherenceExponent = -4 } label: { Text(Theme.caps("Hagan 2002 – ") + "10⁻⁴ s").textCase(nil) }
            .buttonStyle(.bauhaus(.outline, compact: true))
    }
}

/// Owns the SceneKit nodes and recolours them from the simulation state.
/// Palette: state A black, state B grey, superposed yellow (pulsing), just-collapsed red, on white.
@MainActor
final class MicrotubuleScene {
    let scene = SCNScene()
    let camera = SCNNode()
    private var materials: [SCNMaterial] = []
    private let colorA = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)     // ink, #121212
    private let colorB = UIColor(red: 0.54, green: 0.54, blue: 0.54, alpha: 1)     // #8A8A8A
    private let colorS = UIColor(red: 0.949, green: 0.761, blue: 0.188, alpha: 1)  // #F2C230
    private let colorR = UIColor(red: 0.839, green: 0.157, blue: 0.157, alpha: 1)  // #D62828

    init() {
        scene.background.contents = UIColor.white
        let proto = 13, rings = 30
        let radius: Float = 1.0, dz: Float = 0.26
        let sphere = SCNSphere(radius: 0.11)
        sphere.segmentCount = 16
        let pivot = SCNNode()
        for r in 0 ..< rings {
            for p in 0 ..< proto {
                let m = SCNMaterial()
                m.lightingModel = .lambert          // matte, flat-reading colour fields; no specular sheen
                m.diffuse.contents = colorA
                let g = sphere.copy() as! SCNSphere
                g.materials = [m]
                let n = SCNNode(geometry: g)
                let angle = Float(p) / Float(proto) * 2 * .pi
                let z = Float(r) * dz + Float(p) * (3 * dz / Float(proto)) - Float(rings) * dz / 2
                n.position = SCNVector3(radius * cos(angle), z, radius * sin(angle))
                pivot.addChildNode(n)
                materials.append(m)
            }
        }
        // Inner lumen as a pale grey core for depth.
        let lumen = SCNCylinder(radius: 0.80, height: CGFloat(Float(rings) * dz + 0.3))
        let lm = SCNMaterial()
        lm.lightingModel = .constant
        lm.diffuse.contents = UIColor(white: 0.90, alpha: 1)
        lumen.materials = [lm]
        pivot.addChildNode(SCNNode(geometry: lumen))
        // Tilt the spinning lattice onto a diagonal so it fills the frame and clears the key at top left.
        let tilt = SCNNode()
        tilt.eulerAngles = SCNVector3(0, 0, -0.42)
        tilt.addChildNode(pivot)
        scene.rootNode.addChildNode(tilt)

        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 38
        camera.camera?.projectionDirection = .vertical
        camera.position = SCNVector3(9.4, 2.4, 9.4)
        camera.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(camera)

        // Neutral key light plus an even ambient fill: honest colours, no coloured lights.
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 900
        key.light?.color = UIColor.white
        key.eulerAngles = SCNVector3(-0.6, 0.7, 0)
        scene.rootNode.addChildNode(key)
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .ambient
        fill.light?.intensity = 420
        fill.light?.color = UIColor.white
        scene.rootNode.addChildNode(fill)

        pivot.runAction(.repeatForever(.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 40)))
    }

    func apply(_ sim: OrchORSimulation) {
        let flash = CGFloat(sim.flash)
        for i in 0 ..< materials.count {
            let m = materials[i]
            switch sim.states[i] {
            case .a, .b:
                if sim.lastCollapsed[i] && flash > 0 {
                    m.diffuse.contents = colorR
                    m.emission.contents = colorR.withAlphaComponent(1).multiplied(by: 0.55 * flash)
                } else {
                    m.diffuse.contents = sim.states[i] == .a ? colorA : colorB
                    m.emission.contents = UIColor.black
                }
            case .superposed:
                let k = CGFloat(0.5 + 0.5 * sin(Double(sim.phase[i]) * 2 * .pi))
                m.diffuse.contents = colorS
                m.emission.contents = colorS.multiplied(by: 0.18 + 0.32 * k)
            }
        }
    }
}

private extension UIColor {
    func multiplied(by k: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r * k, green: g * k, blue: b * k, alpha: 1)
    }
}
