import SwiftUI
import UIKit
import TrapCore
import TrapDesign
import TrapPlatform

/// The whole app below the `@main` entry. The app target's only view.
@MainActor
public struct TrapAppRoot: View {
    @State private var app: AppModel

    public init() {
        BWAppearance.install()                                       // Inter and Bebas Neue, navigation bar titles
        _app = State(initialValue: DemoMode.isOn ? DemoMode.makeApp() : AppModel())
    }
    init(app: AppModel) { _app = State(initialValue: app) }

    public var body: some View {
        BreakpointReader { AuthGate { AppShell() } }
            .environment(app)
            .environment(app.record)
            .lifecycle(app.lifecycle)
            .tint(BW.tint)
    }
}

/// The seven places of the app: the bottom nav on iPhone, sidebar rows on iPad.
public enum AppSection: String, CaseIterable, Identifiable, Sendable {
    case home, record, timer, rounds, analysis, schemes, settings
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .home: return "Home"
        case .record: return "Record"
        case .timer: return "Timer"
        case .rounds: return "Rounds"
        case .analysis: return "Analysis"
        case .schemes: return "Schemes"
        case .settings: return "Settings"
        }
    }
    public var symbol: String {
        switch self {
        case .home: return "house"
        case .record: return "square.grid.3x3"
        case .timer: return "stopwatch"
        case .rounds: return "list.bullet.rectangle"
        case .analysis: return "chart.bar"
        case .schemes: return "tablecells"
        case .settings: return "gearshape"
        }
    }
}

/// The theme's bottom nav on iPhone, `NavigationSplitView` with an ink sidebar on iPad. The selected place survives a
/// relaunch.
@MainActor
struct AppShell: View {
    @Environment(\.breakpoint) private var breakpoint
    @Environment(AppModel.self) private var app
    @AppStorage(AppState.sectionKey) private var selectedRaw = AppSection.home.rawValue
    @State private var columns = NavigationSplitViewVisibility.all

    private var selection: Binding<AppSection> {
        Binding(get: { AppSection(rawValue: selectedRaw) ?? .home }, set: { selectedRaw = $0.rawValue })
    }

    var body: some View {
        Group {
            if breakpoint.isSplit {
                NavigationSplitView(columnVisibility: $columns) {
                    Sidebar(selection: selection)
                        .navigationSplitViewColumnWidth(breakpoint.sidebarWidth)
                } detail: {
                    NavigationStack { SectionScreen(section: selection.wrappedValue) }
                }
                .navigationSplitViewStyle(.balanced)              // sidebar stays beside the content in portrait
            } else {
                PhoneShell(selection: selection)
            }
        }
        .overlay(alignment: .top) {
            if let problem = app.storeProblem {
                Text(problem)
                    .font(BWFont.note)
                    .foregroundStyle(BW.danger.foreground)
                    .padding(BWMetrics.s3)
                    .frame(maxWidth: .infinity)
                    .background(BW.danger.background)
            }
        }
    }
}

/// iPhone: one navigation stack per place under `BWBottomNav`. A place is built the first time it is opened and then
/// kept, so each keeps its scroll position and pushed screens as a tab would. Analysis, Schemes and Settings share the
/// More slot.
/// The bar steps aside while the keyboard is up.
@MainActor
private struct PhoneShell: View {
    @Binding var selection: AppSection
    @State private var opened: Set<AppSection> = []
    @State private var keyboardUp = false

    private static let main: [AppSection] = [.home, .record, .timer, .rounds]
    private static let more: [AppSection] = [.analysis, .schemes, .settings]

    var body: some View {
        ZStack {
            ForEach(AppSection.allCases) { s in
                if opened.contains(s) || s == selection {
                    let on = s == selection
                    NavigationStack { SectionScreen(section: s) }
                        .opacity(on ? 1 : 0)
                        .allowsHitTesting(on)
                        .accessibilityHidden(!on)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !keyboardUp {
                BWBottomNav(items: Self.main.map(item), more: Self.more.map(item), selection: $selection)
                    .padding(.horizontal, BWMetrics.gutter)
                    .padding(.bottom, BWMetrics.s1)
            }
        }
        .onChange(of: selection, initial: true) { _, s in opened.insert(s) }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in keyboardUp = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardUp = false }
    }

    private func item(_ s: AppSection) -> BWNavItem<AppSection> { BWNavItem(s, title: s.title, symbol: s.symbol) }
}

/// The ink sidebar on iPad.
@MainActor
private struct Sidebar: View {
    @Binding var selection: AppSection
    var body: some View {
        List {
            ForEach(AppSection.allCases) { s in
                Button { selection = s } label: {
                    Label(s.title, systemImage: s.symbol)
                        .font(BWFont.body.weight(selection == s ? .bold : .regular))
                        .foregroundStyle(selection == s ? BW.onAccent : BW.onPanel)
                        .frame(maxWidth: .infinity, minHeight: BWMetrics.controlHeight, alignment: .leading)
                        .padding(.horizontal, BWMetrics.s3)
                        .background(selection == s ? BW.accentFill : Color.clear, in: RoundedRectangle(cornerRadius: BWMetrics.radiusMD))
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .accessibilityAddTraits(selection == s ? .isSelected : [])
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(BW.panel)
        .navigationTitle(AppConstants.displayName)
    }
}

/// One place of the app.
@MainActor
struct SectionScreen: View {
    let section: AppSection

    var body: some View {
        switch section {
        case .home: HomeScreen()
        case .record: AdaptiveSplit { RecordScreen() } detail: { TimerScreen() }
        case .timer: TimerScreen()
        case .rounds: RoundsScreen()
        case .analysis: AnalysisScreen()
        case .schemes: SchemesScreen()
        case .settings: SettingsScreen()
        }
    }
}
