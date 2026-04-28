import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: LauncherViewModel
    @State private var apiKey = ""
    @State private var offlineMode = false

    var body: some View {
        TabView {
            Form {
                Section("Launcher") {
                    Text("unelaborate")
                    Text("Native macOS Minecraft launcher")
                        .foregroundStyle(.secondary)
                }
                Section("Account") {
                    Text(viewModel.authMessage)
                    Button("Microsoft Login") {
                        Task { await viewModel.beginMicrosoftLogin() }
                    }
                }
            }
            .tabItem { Label("General", systemImage: "gear") }

            Form {
                Section("Installed JVMs") {
                    if viewModel.jvms.isEmpty {
                        Text("No JVMs installed")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.jvms) { jvm in
                            HStack {
                                Text(jvm.name)
                                Spacer()
                                Text("Java \(jvm.javaVersion)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Install") {
                    HStack {
                        Button("Install Java 17") { Task { await viewModel.installJVM(version: 17) } }
                        Button("Install Java 21") { Task { await viewModel.installJVM(version: 21) } }
                    }
                }
            }
            .tabItem { Label("Java", systemImage: "terminal") }

            Form {
                Section("CurseForge") {
                    TextField("API Key", text: $apiKey)
                    Button("Save Key") {
                        Task {
                            let config = (try? await ConfigService().load()) ?? LauncherConfig()
                            var mutable = config
                            mutable.curseForgeAPIKey = apiKey
                            try? await ConfigService().save(mutable)
                        }
                    }
                }
            }
            .tabItem { Label("API Keys", systemImage: "key") }

            Form {
                Section("Servers") {
                    ForEach(viewModel.servers) { server in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(server.name).font(.headline)
                            Text("\(server.address):\(server.port)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.servers.remove(atOffsets: indexSet)
                        Task { await viewModel.saveServers() }
                    }
                }
            }
            .tabItem { Label("Servers", systemImage: "network") }
        }
        .padding(20)
        .frame(width: 560, height: 400)
    }
}
