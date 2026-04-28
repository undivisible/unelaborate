import SwiftUI

struct UserPresetPanel: View {
    @ObservedObject var viewModel: LauncherViewModel
    @State private var showCreate = false
    @State private var newPresetName = ""
    @State private var newPresetDescription = ""
    @State private var newPresetSlugs = ""
    @State private var showImport = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Presets")
                    .font(.headline)
                Spacer()
                Button("Import") { showImport = true }
                Button("New") { showCreate = true }
            }

            if viewModel.userPresets.isEmpty {
                Text("No presets. Create one from mod slugs.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.userPresets) { preset in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name).font(.subheadline.weight(.semibold))
                            if !preset.description.isEmpty {
                                Text(preset.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Text("\(preset.projectSlugs.count) mods")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Apply") {
                            Task { await viewModel.applyPreset(preset) }
                        }
                        Button("Export") {
                            let panel = NSSavePanel()
                            panel.nameFieldStringValue = "\(preset.name).json"
                            if panel.runModal() == .OK, let url = panel.url {
                                viewModel.exportPreset(preset, to: url)
                            }
                        }
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.deletePreset(preset) }
                        }
                    }
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Create Preset")
                    .font(.title2.weight(.semibold))
                TextField("Name", text: $newPresetName)
                TextField("Description", text: $newPresetDescription)
                TextEditor(text: $newPresetSlugs)
                    .frame(minHeight: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                Text("Enter Modrinth project slugs, one per line")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Button("Cancel") { showCreate = false }
                    Button("Create") {
                        let slugs = newPresetSlugs.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        Task {
                            await viewModel.createPreset(name: newPresetName, description: newPresetDescription, slugs: slugs)
                            newPresetName = ""
                            newPresetDescription = ""
                            newPresetSlugs = ""
                            showCreate = false
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
            .frame(width: 420)
        }
        .fileImporter(isPresented: $showImport, allowedContentTypes: [.json]) { result in
            if case let .success(url) = result {
                Task { await viewModel.importPreset(from: url) }
            }
        }
    }
}
