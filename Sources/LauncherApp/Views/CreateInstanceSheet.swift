import SwiftUI

struct CreateInstanceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LauncherViewModel

    @State private var name = "New Instance"
    @State private var version = "1.21.1"
    @State private var loader: LoaderType = .fabric
    @State private var group = "Default"
    @State private var notes = ""
    @State private var showVersionPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Instance")
                .font(.title2.weight(.semibold))

            TextField("Name", text: $name)

            HStack {
                TextField("Minecraft Version", text: $version)
                Button("Pick") { showVersionPicker = true }
            }

            Picker("Loader", selection: $loader) {
                ForEach(LoaderType.allCases) { value in
                    Text(value.rawValue.capitalized).tag(value)
                }
            }

            TextField("Group", text: $group)
            TextField("Notes", text: $notes)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create") {
                    Task {
                        await viewModel.createInstance(name: name, version: version, loader: loader, group: group, notes: notes)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .sheet(isPresented: $showVersionPicker) {
            VersionPickerSheet(versions: viewModel.availableVersions, selectedVersion: $version)
        }
    }
}

struct VersionPickerSheet: View {
    let versions: [String]
    @Binding var selectedVersion: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Select Version")
                .font(.headline)
            List(versions, id: \.self) { v in
                Button {
                    selectedVersion = v
                    dismiss()
                } label: {
                    HStack {
                        Text(v)
                        if v == selectedVersion {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: 300, height: 400)
    }
}
