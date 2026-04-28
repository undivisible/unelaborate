import SwiftUI

struct ModTogglePanel: View {
    let instance: MinecraftInstance
    @ObservedObject var viewModel: LauncherViewModel
    @State private var files: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per-Instance Mod Toggles")
                .font(.headline)

            ForEach(files, id: \.self) { file in
                let enabled = !file.hasSuffix(".disabled")
                Toggle(isOn: Binding(
                    get: { enabled },
                    set: { newValue in Task { await viewModel.toggleMod(fileName: file, enabled: newValue); refresh() } }
                )) {
                    Text(file)
                }
            }

            Button("Refresh Mod List") { refresh() }
                .onAppear(perform: refresh)
        }
    }

    private func refresh() {
        let urls = (try? FileManager.default.contentsOfDirectory(at: instance.modsDirectory, includingPropertiesForKeys: nil)) ?? []
        files = urls.map(\.lastPathComponent).sorted()
    }
}
