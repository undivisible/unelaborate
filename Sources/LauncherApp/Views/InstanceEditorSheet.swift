import SwiftUI

struct InstanceEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LauncherViewModel
    @State private var name: String = ""
    @State private var group: String = ""
    @State private var notes: String = ""
    @State private var jvmArgs: String = ""
    @State private var javaPath: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Instance")
                .font(.title2.weight(.semibold))

            if let instance = viewModel.selectedInstance {
                TextField("Name", text: $name)
                TextField("Group", text: $group)
                TextField("Notes", text: $notes)
                TextField("JVM Args (space separated)", text: $jvmArgs)
                TextField("Java Path (optional)", text: $javaPath)

                HStack {
                    Spacer()
                    Button("Cancel") { dismiss() }
                    Button("Save") {
                        Task {
                            var updated = instance
                            updated.name = name
                            updated.group = group
                            updated.notes = notes
                            updated.jvmArgs = jvmArgs.split(separator: " ").map(String.init)
                            updated.javaPath = javaPath.isEmpty ? nil : javaPath
                            viewModel.selectedInstance = updated
                            await viewModel.saveSelectedInstance()
                            dismiss()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(20)
        .frame(width: 480)
        .onAppear {
            if let instance = viewModel.selectedInstance {
                name = instance.name
                group = instance.group
                notes = instance.notes
                jvmArgs = instance.jvmArgs.joined(separator: " ")
                javaPath = instance.javaPath ?? ""
            }
        }
    }
}
