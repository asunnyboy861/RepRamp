import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .rampBackground()
    }
}

struct MainTabView: View {
    @State private var showSettings = false
    @State private var selection: Int = {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--qa-tab-plans") { return 1 }
        if args.contains("--qa-tab-progress") { return 2 }
        if args.contains("--qa-tab-coach") { return 3 }
        #endif
        return 0
    }()

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                TodayView(showSettings: $showSettings)
            }
            .tabItem { Label("Today", systemImage: "flame.fill") }
            .tag(0)

            NavigationStack {
                PlansView()
            }
            .tabItem { Label("Plans", systemImage: "list.bullet.rectangle") }
            .tag(1)

            NavigationStack {
                ProgressViewScreen()
            }
            .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
            .tag(2)

            NavigationStack {
                CoachView()
            }
            .tabItem { Label("Coach", systemImage: "brain.head.profile") }
            .tag(3)
        }
        .tint(Theme.orange)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
