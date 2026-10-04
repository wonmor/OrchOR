import SwiftUI
import SceneKit

/// 3-D microtubule lattice. Each sphere is a tubulin dimer; colour shows its state.
struct MicrotubuleView: View {
    @Environment(OrchORSimulation.self) private var sim
    @State private var scene = MicrotubuleScene()
    @State private var showAbout = false

    var body: some View {
        @Bindable var sim = sim
        NavigationStack {
            ZStack {
                Theme.gradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        ZStack(alignment: .topLeading) {
                            SceneView(scene: scene.scene, pointOfView: scene.camera,
                                      options: [.allowsCameraControl, .autoenablesDefaultLighting])
                                .frame(height: 360)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.cardStroke))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.white.opacity(Double(sim.flash) * 0.55))
                                        .allowsHitTesting(false)
                                }
                            legend.padding(10)
                        }
                        readouts
                        controls(sim: $sim)
                    }
                    .padding()
                }
            }
            .navigationTitle("Orch-OR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button { showAbout = true } label: { Image(systemName: "info.circle") } }
            }
            .sheet(isPresented: $showAbout) { AboutView() }
            .onChange(of: sim.simTime) { _, _ in scene.apply(sim) }
            .onAppear { scene.apply(sim) }
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 4) {
            legendRow(Theme.teal.opacity(0.7), "tubulin, state A")
            legendRow(Color(red: 0.25, green: 0.45, blue: 0.95), "tubulin, state B")
            legendRow(Theme.violet, "in superposition")
            legendRow(.white, "objective reduction")
        }
        .font(.caption2)
        .padding(8)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func legendRow(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 6) { Circle().fill(c).frame(width: 8, height: 8); Text(t) }
    }

    private var readouts: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Readout(label: "superposed dimers", value: "\(sim.superposedCount) / \(sim.count)", color: Theme.violet)
                Readout(label: "represents", value: sim.effectiveTubulins.compact + " tubulins")
                Readout(label: "E_G", value: sim.gravitationalSelfEnergy.sci("J"))
            }
            HStack(alignment: .top) {
                Readout(label: "τ = ħ/E_G", value: sim.tau.timeString, color: Theme.amber)
                Readout(label: "OR events", value: "\(sim.events.count)")
                Readout(label: "event rate", value: sim.eventFrequencyHz.map { String(format: "%.0f Hz", $0) } ?? "—", color: Theme.teal)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("∫E_G dt → ħ").font(.caption)
                    Spacer()
                    Text(String(format: "%.0f%%", sim.progressToCollapse * 100)).font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08))
                        Capsule().fill(LinearGradient(colors: [Theme.violet, .white], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * sim.progressToCollapse)
                    }
                }
                .frame(height: 10)
                Text("Superposition grows by orchestration, gravitational self-energy accumulates, and at ħ the set self-collapses: one 'moment'. Simulation runs \(Int(sim.slowMotion))× slower than real time.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private func controls(sim: Bindable<OrchORSimulation>) -> some View {
        VStack(spacing: 10) {
            HStack {
                Button { self.sim.running.toggle() } label: {
                    Label(self.sim.running ? "Pause" : "Run", systemImage: self.sim.running ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent).tint(Theme.teal).foregroundStyle(.black)
                Button { self.sim.reset() } label: { Label("Reset", systemImage: "arrow.counterclockwise") }
                    .buttonStyle(.bordered)
                Spacer()
            }
            LabeledSlider(label: "Orchestration (MAP coupling)", value: sim.orchestration, range: 0 ... 1) { String(format: "%.2f", $0) }
            LabeledSlider(label: "Each displayed dimer stands for", value: sim.representationExponent, range: 5 ... 9) { "10^\(String(format: "%.1f", $0)) dimers" }
            LabeledSlider(label: "Slow motion", value: sim.slowMotion, range: 1 ... 200) { "\(Int($0))×" }
            Toggle(isOn: sim.decoherenceEnabled) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Environmental decoherence").font(.caption)
                    Text("Off = Orch-OR's assumption that microtubules are shielded").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .tint(Theme.rose)
            if self.sim.decoherenceEnabled {
                LabeledSlider(label: "Decoherence time", value: sim.decoherenceExponent, range: -13 ... 0) { pow(10, $0).timeString }
                HStack {
                    Button("Tegmark 2000: 10⁻¹³ s") { self.sim.decoherenceExponent = -13 }
                    Button("Hagan et al. 2002: 10⁻⁴ s") { self.sim.decoherenceExponent = -4 }
                }
                .font(.caption2).buttonStyle(.bordered).tint(Theme.rose)
            }
        }
        .card()
    }
}

/// Owns the SceneKit nodes and recolours them from the simulation state.
@MainActor
final class MicrotubuleScene {
    let scene = SCNScene()
    let camera = SCNNode()
    private var nodes: [SCNNode] = []
    private var materials: [SCNMaterial] = []
    private let colorA = UIColor(red: 0.30, green: 0.70, blue: 0.62, alpha: 1)
    private let colorB = UIColor(red: 0.25, green: 0.45, blue: 0.95, alpha: 1)

    init() {
        scene.background.contents = UIColor(red: 0.02, green: 0.04, blue: 0.09, alpha: 1)
        let proto = 13, rings = 30
        let radius: Float = 1.0, dz: Float = 0.26
        let sphere = SCNSphere(radius: 0.11)
        sphere.segmentCount = 12
        for r in 0 ..< rings {
            for p in 0 ..< proto {
                let m = SCNMaterial()
                m.diffuse.contents = colorA
                m.lightingModel = .physicallyBased
                m.roughness.contents = 0.6
                let g = sphere.copy() as! SCNSphere
                g.materials = [m]
                let n = SCNNode(geometry: g)
                let angle = Float(p) / Float(proto) * 2 * .pi
                let z = Float(r) * dz + Float(p) * (3 * dz / Float(proto)) - Float(rings) * dz / 2
                n.position = SCNVector3(radius * cos(angle), z, radius * sin(angle))
                scene.rootNode.addChildNode(n)
                nodes.append(n)
                materials.append(m)
            }
        }
        // Faint inner lumen cylinder for depth cue.
        let lumen = SCNCylinder(radius: 0.78, height: CGFloat(Float(rings) * dz))
        let lm = SCNMaterial()
        lm.diffuse.contents = UIColor(white: 1, alpha: 0.04)
        lm.transparency = 0.9
        lm.isDoubleSided = true
        lumen.materials = [lm]
        scene.rootNode.addChildNode(SCNNode(geometry: lumen))

        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 42
        camera.position = SCNVector3(7.6, 3.6, 7.6)
        camera.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(camera)

        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .omni
        light.light?.intensity = 900
        light.position = SCNVector3(3, 5, 4)
        scene.rootNode.addChildNode(light)

        let spin = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 40))
        let pivot = SCNNode()
        scene.rootNode.childNodes.filter { $0.geometry != nil }.forEach { n in n.removeFromParentNode(); pivot.addChildNode(n) }
        scene.rootNode.addChildNode(pivot)
        pivot.runAction(spin)
    }

    func apply(_ sim: OrchORSimulation) {
        let flash = CGFloat(sim.flash)
        for i in 0 ..< materials.count {
            let m = materials[i]
            switch sim.states[i] {
            case .a:
                m.diffuse.contents = colorA
                m.emission.contents = UIColor(white: sim.lastCollapsed[i] ? flash : 0, alpha: 1)
            case .b:
                m.diffuse.contents = colorB
                m.emission.contents = UIColor(white: sim.lastCollapsed[i] ? flash : 0, alpha: 1)
            case .superposed:
                let k = 0.5 + 0.5 * sin(Double(sim.phase[i]) * 2 * .pi)
                m.diffuse.contents = UIColor(red: 0.70, green: 0.50, blue: 1.0, alpha: 1)
                m.emission.contents = UIColor(red: 0.55 * k + 0.15, green: 0.35 * k + 0.1, blue: 0.9 * k + 0.1, alpha: 1)
            }
        }
    }
}
