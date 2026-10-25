import SwiftUI
import SceneKit

/// 3-D microtubule lattice. Each sphere is a tubulin dimer; colour shows its state.
struct MicrotubuleView: View {
    @Environment(OrchORSimulation.self) private var sim
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var scene = MicrotubuleScene()
    @State private var showAbout = false

    var body: some View {
        @Bindable var sim = sim
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(index: "01", kicker: "Orch-OR · Lattice", title: "microtubule", accent: Theme.blue) {
                    Button { showAbout = true } label: { Label("About", systemImage: "info") }
                        .buttonStyle(.bauhaus(.outline(Theme.paper), compact: true))
                }
                if hSize == .regular {
                    HStack(alignment: .top, spacing: 16) {
                        sceneBlock(height: 640)
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
        .background(Theme.ink)
        .sheet(isPresented: $showAbout) { AboutView() }
        .onChange(of: sim.simTime) { _, _ in scene.apply(sim) }
        .onChange(of: sim.stagedRevision) { _, _ in scene.apply(sim) }
        .onAppear { scene.apply(sim) }
    }

    private func sceneBlock(height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            SceneView(scene: scene.scene, pointOfView: scene.camera, options: [.allowsCameraControl])
                .frame(height: height)
                .accessibilityLabel("3D microtubule lattice, \(sim.superposedCount) of \(sim.count) dimers in superposition")
            // Objective-reduction flash: a flat red field, no glow.
            Theme.red.opacity(Double(sim.flash) * 0.10)
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
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Theme.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: height)
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(Rectangle().strokeBorder(Theme.paper.opacity(0.9), lineWidth: Theme.ruleWidth))
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            KeyRow(glyph: "arrow.up", color: Theme.paper, text: "Tubulin · state A")
            KeyRow(glyph: "arrow.down", color: Theme.blueText, text: "Tubulin · state B")
            KeyRow(glyph: "arrow.up.arrow.down", color: Theme.yellow, text: "Superposition")
            KeyRow(glyph: "bolt", color: Theme.redText, text: "Objective reduction")
        }
        .padding(10)
        .background(Theme.ink.opacity(0.88))
        .overlay(Rectangle().strokeBorder(Theme.rule, lineWidth: Theme.ruleWidth))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Key: white, state A; blue, state B; yellow, superposition; red, objective reduction")
    }

    private var readouts: some View {
        VStack(alignment: .leading, spacing: 14) {
            Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 14) {
                GridRow {
                    Readout(label: "Superposed", value: "\(sim.superposedCount)/\(sim.count)", color: Theme.yellow)
                    Readout(label: "Represents", value: sim.effectiveTubulins.compact)
                    Readout(label: "E_G", value: sim.gravitationalSelfEnergy.sci("J", digits: 1))
                }
                GridRow { HRule().gridCellColumns(3) }
                GridRow {
                    Readout(label: "τ = ħ/E_G", value: sim.tau.timeString, color: Theme.yellow)
                    Readout(label: "OR events", value: "\(sim.events.count)")
                    Readout(label: "Event rate", value: sim.eventFrequencyHz.map { String(format: "%.0f Hz", $0) } ?? "—", color: Theme.blueText)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    TrackedText("∫E_G dt → ħ", color: Theme.paper)
                    Spacer()
                    Text(String(format: "%.0f%%", sim.progressToCollapse * 100))
                        .font(.system(.footnote, design: .monospaced).weight(.semibold))
                        .foregroundStyle(Theme.paper)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Theme.raised
                        (sim.progressToCollapse >= 0.999 || sim.flash > 0.05 ? Theme.red : Theme.yellow)
                            .frame(width: geo.size.width * sim.progressToCollapse)
                    }
                }
                .frame(height: 12)
                .overlay(Rectangle().strokeBorder(Theme.rule, lineWidth: Theme.ruleWidth))
                .accessibilityElement()
                .accessibilityLabel("Progress to collapse")
                .accessibilityValue(String(format: "%.0f percent", sim.progressToCollapse * 100))
                Text("Superposition grows by orchestration, gravitational self-energy accumulates, and at ħ the set self-collapses: one 'moment'. Simulation runs \(Int(sim.slowMotion))× slower than real time.")
                    .font(.footnote).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .panel(accent: Theme.yellow)
    }

    private func controls(sim: Bindable<OrchORSimulation>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Button { self.sim.running.toggle() } label: {
                    Text(self.sim.running ? "Pause" : "Run")
                }
                .buttonStyle(.bauhaus(.filled(Theme.yellow)))
                Button { self.sim.reset() } label: { Text("Reset") }
                    .buttonStyle(.bauhaus(.outline(Theme.paper)))
                Spacer(minLength: 0)
            }
            BauhausSlider(label: "Orchestration (MAP coupling)", value: sim.orchestration, range: 0 ... 1, accent: Theme.yellow) { String(format: "%.2f", $0) }
            BauhausSlider(label: "Each displayed dimer stands for", value: sim.representationExponent, range: 5 ... 9, accent: Theme.blue) { "10" + String(format: "%.1f", $0).superscript }
            BauhausSlider(label: "Slow motion", value: sim.slowMotion, range: 1 ... 200, accent: Theme.paper) { "\(Int($0))×" }
            HRule()
            Toggle(isOn: sim.decoherenceEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    TrackedText("Environmental decoherence", color: Theme.paper)
                    Text("Off = Orch-OR's assumption that microtubules are shielded")
                        .font(.footnote).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
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
        Button { self.sim.decoherenceExponent = -13 } label: { Text(Theme.caps("Tegmark 2000 · ") + "10⁻¹³ s").textCase(nil) }
            .buttonStyle(.bauhaus(.outline(Theme.redText), compact: true))
        Button { self.sim.decoherenceExponent = -4 } label: { Text(Theme.caps("Hagan 2002 · ") + "10⁻⁴ s").textCase(nil) }
            .buttonStyle(.bauhaus(.outline(Theme.redText), compact: true))
    }
}

/// Owns the SceneKit nodes and recolours them from the simulation state.
/// Palette: state A bone white, state B Bauhaus blue, superposed yellow (pulsing), just-collapsed red.
@MainActor
final class MicrotubuleScene {
    let scene = SCNScene()
    let camera = SCNNode()
    private var materials: [SCNMaterial] = []
    private let colorA = UIColor(red: 0.85, green: 0.83, blue: 0.79, alpha: 1)     // bone, #D9D4C9
    private let colorB = UIColor(red: 0.18, green: 0.42, blue: 1.00, alpha: 1)     // #2F6BFF
    private let colorS = UIColor(red: 0.95, green: 0.72, blue: 0.02, alpha: 1)     // #F2B705
    private let colorR = UIColor(red: 0.90, green: 0.23, blue: 0.18, alpha: 1)     // #E63B2E

    init() {
        scene.background.contents = UIColor(red: 0.055, green: 0.055, blue: 0.055, alpha: 1)   // ink
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
        // Inner lumen as a dark charcoal core for depth.
        let lumen = SCNCylinder(radius: 0.80, height: CGFloat(Float(rings) * dz + 0.3))
        let lm = SCNMaterial()
        lm.lightingModel = .constant
        lm.diffuse.contents = UIColor(white: 0.10, alpha: 1)
        lumen.materials = [lm]
        pivot.addChildNode(SCNNode(geometry: lumen))
        scene.rootNode.addChildNode(pivot)

        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 38
        camera.camera?.projectionDirection = .vertical
        camera.position = SCNVector3(10.5, 3.2, 10.5)
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
