import SwiftUI

struct LearnView: View {
    private struct Card: Identifiable { let id = UUID(); let title: String; let body: String; let tint: Color }

    private let cards: [Card] = [
        Card(title: "The claim in one paragraph",
             body: "Orchestrated Objective Reduction (Orch-OR), proposed by physicist Roger Penrose and anaesthesiologist Stuart Hameroff in the mid-1990s, says consciousness arises from quantum computations inside neurons, in protein lattices called microtubules. Superpositions of tubulin states build up, are 'orchestrated' by the cell's own machinery, and then collapse on their own through a gravitational mechanism Penrose calls objective reduction. Each collapse is a discrete moment of experience.",
             tint: Theme.ink),
        Card(title: "Microtubules",
             body: "Microtubules are hollow cylinders about 25 nm wide, built from 13 protofilaments of tubulin dimers in a helical lattice, exactly the geometry on the first tab. They give cells their shape and act as rails for transport. Neurons are full of them. Hameroff's starting point was that general anaesthetics, which switch consciousness off, bind to hydrophobic pockets in tubulin and other proteins rather than to any single receptor.",
             tint: Theme.ink),
        Card(title: "Tubulin as a qubit",
             body: "The theory treats each tubulin dimer as able to occupy two conformations, and, crucially, a quantum superposition of both. Neighbouring dimers in superposition are assumed to become entangled, so coherence can spread across a microtubule and, through gap junctions, across many neurons. In the simulation this is the yellow patch growing by 'orchestration'.",
             tint: Theme.yellow),
        Card(title: "Objective reduction (Penrose)",
             body: "Standard quantum mechanics does not say when a superposition becomes a definite outcome. Penrose proposes it happens objectively, when the two branches differ enough in mass distribution that their spacetime geometries diverge. The threshold is set by the gravitational self-energy E_G of that difference: the superposition lasts about τ ≈ ħ / E_G, then self-collapses. The same criterion was reached independently by Lajos Diósi. The outcome is held to be non-computable, which for Penrose is what distinguishes conscious insight from algorithmic processing (the argument of 'The Emperor's New Mind').",
             tint: Theme.red),
        Card(title: "Orchestration (Hameroff)",
             body: "'Orchestrated' refers to microtubule-associated proteins, synaptic inputs and the cell's biochemistry tuning which superpositions form and when they collapse, so that reductions are structured rather than random noise. The collapse is proposed to select a definite tubulin configuration that then steers cell behaviour, closing the loop from quantum event to neural firing.",
             tint: Theme.yellow),
        Card(title: "Why 40 Hz",
             body: "Hameroff & Penrose (2014) run the numbers backwards: for a reduction every 25 ms, matching 40 Hz gamma synchrony seen in EEG during conscious states, E_G must be about ħ / 0.025 s. With tubulins displaced by roughly a nuclear diameter, that needs around 2×10¹⁰ tubulins in coherent superposition, which at 0.1% of each neuron's tubulins is about 20,000 neurons. The Calculator tab lets you move those dials.",
             tint: Theme.ink),
        Card(title: "The main objection: decoherence",
             body: "The brain is warm, wet and noisy. Max Tegmark (2000) calculated that superpositions in microtubules would decohere in about 10⁻¹³ s, ten orders of magnitude too fast for anything neural. Hagan, Hameroff & Tuszynski (2002) replied that Tegmark modelled the wrong system, and with ordered water, counter-ion screening and actin gel they got 10⁻⁵ to 10⁻⁴ s. That is still far short of 25 ms. Flip on 'environmental decoherence' in the simulation and watch the coherent patch die before it reaches ħ. Christof Koch and Klaus Hepp (2006) also argued there is no evidence the brain uses quantum computation.",
             tint: Theme.red),
        Card(title: "Evidence the proponents cite",
             body: "Anaesthetics acting on microtubules: a 2024 eNeuro study (Khan, Wiest and colleagues) found that the microtubule-stabilising drug epothilone B delayed isoflurane-induced unconsciousness in rats by about a minute. Quantum optical effects in tubulin: Babcock and colleagues (2024, J. Phys. Chem. B) reported ultraviolet superradiance across tryptophan networks in microtubules at physiological temperature, and Kalra and colleagues (2023) saw excitation energy travelling further through microtubules than classical diffusion predicts, with anaesthetics shortening it. Supporters read these as signs that microtubules host long-range quantum effects. Critics note none of them show tubulin superpositions lasting milliseconds, let alone gravitational collapse.",
             tint: Theme.ink),
        Card(title: "Where it stands",
             body: "Orch-OR is a minority view. Most neuroscientists consider consciousness a classical, large-scale property of neural networks, and the objective-reduction part has not been observed in any physical system; experiments by Donadi and colleagues (2021) on spontaneous radiation have already constrained the simplest Diósi–Penrose variant. What the theory has going for it is that it makes specific, falsifiable claims about timescales and numbers, which is why it is worth being able to compute them, and why this app exists.",
             tint: Theme.ink),
    ]

    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(index: "04", kicker: "The theory, both sides", title: "learn", accent: Theme.yellow)
                brandBlock
                colourKey
                if hSize == .regular {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16, alignment: .top), GridItem(.flexible(), spacing: 16, alignment: .top)],
                              alignment: .leading, spacing: 16) {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { i, c in article(i, c) }
                    }
                } else {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { i, c in article(i, c) }
                }
                referencesPanel
            }
            .pageFrame()
        }
        .background(Theme.ground)
    }

    private var colourKey: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Colour key", subtitle: "Each primary means one thing on every screen")
            KeyRow(glyph: "arrow.up.arrow.down", color: Theme.yellow, text: "Yellow: coherent superposition")
            KeyRow(glyph: "bolt", color: Theme.red, text: "Red: objective reduction and decoherence")
            KeyRow(glyph: "hand.tap", color: Theme.blue, text: "Blue: what you control")
            KeyRow(glyph: "arrow.up", color: Theme.stateA, text: "Black: tubulin state A")
            KeyRow(glyph: "arrow.down", color: Theme.stateB, text: "Grey: tubulin state B")
        }
        .panel()
    }

    private var brandBlock: some View {
        HStack(alignment: .center, spacing: 14) {
            BrandMark(size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("Orch-OR Visualizer").font(BFont.heading()).foregroundStyle(Theme.ink)
                Note("Penrose–Hameroff objective reduction, made computable. Nine short notes and the papers behind them.")
            }
        }
        .panel()
    }

    private func article(_ i: Int, _ c: Card) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Text(String(format: "%02d", i + 1))
                    .font(BFont.display(30, relativeTo: .title))
                    .foregroundStyle(Theme.onField(c.tint))
                    .frame(minWidth: 52, minHeight: 44)
                    .background(c.tint)
                    .accessibilityHidden(true)
                Text(c.title)
                    .font(BFont.heading())
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HRule()
            Text(c.body)
                .font(BFont.callout)
                .lineSpacing(3)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .panel()
    }

    private var referencesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sources").font(BFont.heading()).foregroundStyle(Theme.ink).accessibilityAddTraits(.isHeader)
                Spacer()
                TrackedText("\(sources.count) references", size: 11)
            }
            HRule(height: Theme.thick)
            ForEach(Array(sources.enumerated()), id: \.offset) { i, s in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(String(format: "[%02d]", i + 1))
                        .font(BFont.number(13, relativeTo: .caption))
                        .foregroundStyle(Theme.blue)
                    Note(s)
                }
                .accessibilityElement(children: .combine)
                if i < sources.count - 1 { HRule(color: Theme.hairline, height: 1) }
            }
        }
        .panel(accent: Theme.ink)
    }

    private let sources = [
        "Hameroff S, Penrose R (2014). Consciousness in the universe: A review of the 'Orch OR' theory. Physics of Life Reviews 11(1).",
        "Penrose R (1989). The Emperor's New Mind. (1994) Shadows of the Mind.",
        "Hameroff S, Penrose R (1996). Orchestrated reduction of quantum coherence in brain microtubules. Mathematics and Computers in Simulation 40.",
        "Diósi L (1989). Models for universal reduction of macroscopic quantum fluctuations. Phys. Rev. A 40.",
        "Tegmark M (2000). Importance of quantum decoherence in brain processes. Phys. Rev. E 61.",
        "Hagan S, Hameroff S, Tuszynski J (2002). Quantum computation in brain microtubules: Decoherence and biological feasibility. Phys. Rev. E 65.",
        "Koch C, Hepp K (2006). Quantum mechanics in the brain. Nature 440.",
        "Khan S, Huang Y, Timuçin D, Bailey S, Lee S, Lopes J, Gaunce E, Mosberger J, Zhan M, Abdelrahman B, Zeng X, Wiest MC (2024). Microtubule-stabilizer epothilone B delays anesthetic-induced unconsciousness in rats. eNeuro 11(8).",
        "Babcock NS, Montes-Cabrera G, Oberhofer KE, Chergui M, Celardo GL, Kurian P (2024). Ultraviolet superradiance from mega-networks of tryptophan in biological architectures. J. Phys. Chem. B 128.",
        "Kalra AP et al. (2023). Electronic energy migration in microtubules. ACS Central Science 9.",
        "Donadi S et al. (2021). Underground test of gravity-related wave function collapse. Nature Physics 17.",
    ]
}
