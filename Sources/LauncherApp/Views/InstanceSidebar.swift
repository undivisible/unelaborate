import SwiftUI
import AppKit

struct InstanceSidebar: View {
    @ObservedObject var viewModel: LauncherViewModel
    @Binding var showCreate: Bool
    @State private var sidebarSearch = ""
    @State private var showAccountMenu = false

    var filteredGroups: [(String, [MinecraftInstance])] {
        let query = sidebarSearch.trimmingCharacters(in: .whitespaces)
        let groups = viewModel.groupedInstances
        let filtered: [String: [MinecraftInstance]] = query.isEmpty ? groups : groups.compactMapValues { instances in
            let result = instances.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.mcVersion.localizedCaseInsensitiveContains(query)
            }
            return result.isEmpty ? nil : result
        }
        return filtered.keys.sorted().compactMap { key in
            guard let instances = filtered[key] else { return nil }
            return (key, instances)
        }
    }

    var body: some View {
        List(selection: $viewModel.selectedInstance) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 12))
                TextField("Filter", text: $sidebarSearch)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !sidebarSearch.isEmpty {
                    Button {
                        sidebarSearch = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.quinary, in: RoundedRectangle(cornerRadius: 7))
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 8, trailing: 8))

            // Instances
            if filteredGroups.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text(sidebarSearch.isEmpty ? "No instances" : "No results")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                .listRowSeparator(.hidden)
            } else {
                ForEach(filteredGroups, id: \.0) { group, instances in
                    Section(group) {
                        ForEach(instances) { instance in
                            InstanceRow(instance: instance, viewModel: viewModel)
                                .tag(instance)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            AccountFooter(viewModel: viewModel)
        }
        .frame(minWidth: 220)
    }
}

struct InstanceRow: View {
    let instance: MinecraftInstance
    @ObservedObject var viewModel: LauncherViewModel

    var isInstalled: Bool { viewModel.installedInstanceIDs.contains(instance.id) }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(instance.loader.color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: instance.loader.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(instance.loader.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(instance.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                HStack(spacing: 3) {
                    Text(instance.mcVersion)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(instance.loader.rawValue.capitalized)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if !isInstalled {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Launch") { Task { await viewModel.launchSelectedInstance() } }
            Button("Duplicate") { Task { await viewModel.duplicateInstance(instance) } }
            Divider()
            Button("Show in Finder") { NSWorkspace.shared.open(instance.gameDirectory) }
            Button("Backup") { Task { await viewModel.backupSelectedInstance() } }
            Divider()
            Button("Delete", role: .destructive) { Task { await viewModel.deleteInstance(instance) } }
        }
    }
}

struct AccountFooter: View {
    @ObservedObject var viewModel: LauncherViewModel
    @State private var showMenu = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                showMenu = true
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(.quaternary)
                            .frame(width: 28, height: 28)
                        Text(String(viewModel.currentAccount?.username.prefix(1).uppercased() ?? "?"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(viewModel.currentAccount?.username ?? "Player")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: viewModel.isOffline ? "wifi.slash" : "checkmark.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(viewModel.isOffline ? .orange : .green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showMenu, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Button("Settings") {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                        showMenu = false
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())

                    Divider()

                    Button("Sign Out") {
                        Task { await viewModel.signOut() }
                        showMenu = false
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .padding(.vertical, 4)
                .frame(width: 160)
            }
        }
        .background(.ultraThinMaterial)
    }
}

extension LoaderType {
    var icon: String {
        switch self {
        case .vanilla: return "cube"
        case .fabric: return "leaf"
        case .quilt: return "square.grid.2x2"
        case .neoforge: return "hammer"
        }
    }

    var color: Color {
        switch self {
        case .vanilla: return .orange
        case .fabric: return .green
        case .quilt: return .purple
        case .neoforge: return .blue
        }
    }
}
