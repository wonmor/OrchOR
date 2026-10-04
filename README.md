# Orch-OR Visualizer

iOS app that turns the Penrose–Hameroff "Orchestrated Objective Reduction" theory of consciousness into an
interactive model: a 3D microtubule lattice (SceneKit) where tubulin superpositions seed, spread by
orchestration, accumulate gravitational self-energy and collapse when ∫E_G dt ≥ ħ; a timeline of events
(Swift Charts); a Diósi–Penrose calculator calibrated to Hameroff & Penrose (2014); and a Learn tab that
presents the theory, the decoherence objection and the current evidence with references.

- `project.yml` → `xcodegen generate` → `OrchOR.xcodeproj`
- `OrchOR/Model/` physics constants and the simulation; `OrchOR/Views/` SwiftUI screens
- `fastlane/` App Store metadata, screenshots and lanes (age_rating, privacy, pricing, status, submit, inspect_asc)

© 2026 Wonmo (John) Seong

## Licence and citation
Code is MIT licensed (see LICENSE). If you use or build on this work, please cite it: see `CITATION.cff`.

## Acknowledgement
Implementation was carried out with AI assistance (Claude, Anthropic) under the author's direction; the author takes full responsibility for the design and content.
