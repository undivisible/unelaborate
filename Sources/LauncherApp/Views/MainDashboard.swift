import SwiftUI
import AppKit

struct MainDashboard: View {
    @ObservedObject var viewModel: LauncherViewModel
    let instance: MinecraftInstance
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                InstanceHeader(viewModel: viewModel, instance: instance)

                Divider()

                // Tab bar
                HStack(spacing: 0) {
                    DashboardTab(icon: "puzzlepiece.fill", title: "Mods", isSelected: selectedTab == 0) { selectedTab = 0 }
                    DashboardTab(icon: "photo.fill", title: "Resource Packs", isSelected: selectedTab == 1) { selectedTab = 1 }
                    DashboardTab(icon: "sparkles", title: "Shaders", isSelected: selectedTab == 2) { selectedTab = 2 }
                    DashboardTab(icon: "gearshape.fill", title: "Settings", isSelected: selectedTab == 3) { selectedTab = 3 }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .background(.bar)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        switch selectedTab {
                        case 0: ModsTab(viewModel: viewModel)
                        case 1: ResourcePacksTab(viewModel: viewModel)
                        case 2: ShadersTab(viewModel: viewModel)
                        case 3: InstanceSettingsView(viewModel: viewModel, instance: instance)
                        default: EmptyView()
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if viewModel.showLogPanel {
                    Divider()
                    GameLogPanel(viewModel: viewModel)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }
            }

            // Feedback toast
            if let message = viewModel.feedbackMessage {
                FeedbackToast(message: message)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.feedbackMessage)
    }
}

struct DashboardTab: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                Text(title)
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.07))
                    : nil
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct FeedbackToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.black.opacity(0.78), in: Capsule())
            .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
    }
}

struct InstanceSettingsView: View {
    @ObservedObject var viewModel: LauncherViewModel
    let instance: MinecraftInstance
    @State private var jvmArgs = ""
    @State private var javaPath = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingCard(title: "Java", icon: "cup.and.saucer") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("JVM Arguments (e.g. -Xmx4G)", text: $jvmArgs)
                        .textFieldStyle(.roundedBorder)
                    TextField("Java Path (optional)", text: $javaPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Save") {
                        // save handled by instance editor
                    }
                    .buttonStyle(.bordered)
                }
            }

            SettingCard(title: "Game Directory", icon: "folder") {
                HStack {
                    Text(instance.gameDirectory.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button("Open") { NSWorkspace.shared.open(instance.gameDirectory) }
                        .buttonStyle(.bordered)
                        .contentShape(Rectangle())
                }
            }
        }
        .onAppear {
            jvmArgs = instance.jvmArgs.joined(separator: " ")
            javaPath = instance.javaPath ?? ""
        }
    }
}

struct SettingCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
            content
        }
        .padding(16)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
