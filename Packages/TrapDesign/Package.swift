// swift-tools-version: 5.9
import PackageDescription

// TrapDesign: the TrapShooterPro design system for SwiftUI.
// Flat Glass · Brand Blue palette, Inter and Bebas Neue (bundled, SIL OFL 1.1), metrics and component styles.
// Source of truth for the mapping: docs/design-system.md.
let package = Package(
    name: "TrapDesign",
    platforms: [.iOS(.v17)],
    products: [.library(name: "TrapDesign", targets: ["TrapDesign"])],
    targets: [.target(name: "TrapDesign", resources: [.copy("Resources/Fonts")])]
)
