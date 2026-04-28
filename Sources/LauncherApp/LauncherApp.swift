import SwiftUI

@main
struct LauncherApp: App {
    @StateObject private var viewModel = LauncherViewModel()

    var body: some Scene {
        WindowGroup("unelaborate") {
            Group {
                if viewModel.isAuthenticated {
                    ContentView(viewModel: viewModel)
                } else {
                    WelcomeView(viewModel: viewModel)
                }
            }
            .frame(minWidth: 1100, minHeight: 760)
        }
        .defaultSize(width: 1200, height: 820)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
}
