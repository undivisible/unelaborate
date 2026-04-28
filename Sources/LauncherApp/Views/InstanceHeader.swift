import SwiftUI
import AppKit

struct InstanceHeader: View {
    @ObservedObject var viewModel: LauncherViewModel
    let instance: MinecraftInstance
    @State private var showEditor = false

    var isInstalled: Bool {
        viewModel.installedInstanceIDs.contains(instance.id)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Instance icon + name
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(instance.loader.color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: instance.loader.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(instance.loader.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(instance.name)
                        .font(.system(size: 18, weight: .semibold))
                    HStack(spacing: 4) {
                        Text("Minecraft \(instance.mcVersion)")
                        if instance.loader != .vanilla {
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text(instance.loader.rawValue.capitalized)
                            if let lv = instance.loaderVersion {
                                Text(lv)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                // Single install → play button
                Button {
                    Task { await viewModel.installOrPlay() }
                } label: {
                    Group {
                        if viewModel.isInstalling {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.65)
                                    .tint(.white)
                                Text("Installing…")
                            }
                        } else if isInstalled {
                            Label("Play", systemImage: "play.fill")
                        } else {
                            Label("Install", systemImage: "arrow.down.circle")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 130)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isInstalling)
                .keyboardShortcut(.defaultAction)
                .contentShape(Rectangle())

                // Options menu
                Menu {
                    Button("Edit Instance") { showEditor = true }
                    Button("Open Folder") { NSWorkspace.shared.open(instance.gameDirectory) }
                    Divider()
                    Button("Backup") { Task { await viewModel.backupSelectedInstance() } }
                    Button("Export .mrpack") { Task { await viewModel.exportSelectedInstance() } }
                    Divider()
                    Button("Delete", role: .destructive) { Task { await viewModel.deleteInstance(instance) } }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 32)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .sheet(isPresented: $showEditor) {
            InstanceEditorSheet(viewModel: viewModel)
        }
    }
}
