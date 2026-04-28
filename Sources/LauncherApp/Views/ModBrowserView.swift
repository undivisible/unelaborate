import SwiftUI

// MARK: - Mods Tab

struct ModsTab: View {
    @ObservedObject var viewModel: LauncherViewModel
    @State private var searchQuery = ""
    @State private var results: [ModrinthProject] = []
    @State private var isSearching = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Search bar
            BrowserSearchBar(
                placeholder: "Search mods…",
                query: $searchQuery,
                isSearching: isSearching
            ) {
                performSearch()
            }

            if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                // Popular mods from Modrinth
                PopularSection(
                    title: "Popular Mods",
                    items: viewModel.popularMods,
                    viewModel: viewModel,
                    type: .mod
                )
            } else {
                SearchResultsSection(results: results, viewModel: viewModel, type: .mod)
            }

            // Installed mods toggle list
            InstalledModsSection(instance: viewModel.selectedInstance, viewModel: viewModel)
        }
    }

    private func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { results = []; return }
        isSearching = true
        Task {
            results = (try? await viewModel.searchModrinthResults(query: query, type: .mod)) ?? []
            isSearching = false
        }
    }
}

// MARK: - Resource Packs Tab

struct ResourcePacksTab: View {
    @ObservedObject var viewModel: LauncherViewModel
    @State private var searchQuery = ""
    @State private var results: [ModrinthProject] = []
    @State private var isSearching = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            BrowserSearchBar(
                placeholder: "Search resource packs…",
                query: $searchQuery,
                isSearching: isSearching
            ) {
                performSearch()
            }

            if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                PopularSection(
                    title: "Popular Resource Packs",
                    items: viewModel.popularResourcePacks,
                    viewModel: viewModel,
                    type: .resourcepack
                )
            } else {
                SearchResultsSection(results: results, viewModel: viewModel, type: .resourcepack)
            }
        }
    }

    private func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { results = []; return }
        isSearching = true
        Task {
            results = (try? await viewModel.searchModrinthResults(query: query, type: .resourcepack)) ?? []
            isSearching = false
        }
    }
}

// MARK: - Shaders Tab

struct ShadersTab: View {
    @ObservedObject var viewModel: LauncherViewModel
    @State private var searchQuery = ""
    @State private var results: [ModrinthProject] = []
    @State private var isSearching = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            BrowserSearchBar(
                placeholder: "Search shaders…",
                query: $searchQuery,
                isSearching: isSearching
            ) {
                performSearch()
            }

            if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                PopularSection(
                    title: "Popular Shaders",
                    items: viewModel.popularShaders,
                    viewModel: viewModel,
                    type: .shader
                )
            } else {
                SearchResultsSection(results: results, viewModel: viewModel, type: .shader)
            }
        }
    }

    private func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { results = []; return }
        isSearching = true
        Task {
            results = (try? await viewModel.searchModrinthResults(query: query, type: .shader)) ?? []
            isSearching = false
        }
    }
}

// MARK: - Shared Components

struct BrowserSearchBar: View {
    let placeholder: String
    @Binding var query: String
    let isSearching: Bool
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
                .font(.system(size: 14))

            TextField(placeholder, text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .onSubmit(onSubmit)
                .onChange(of: query) { _, new in
                    if new.trimmingCharacters(in: .whitespaces).isEmpty {
                        onSubmit()
                    }
                }

            if isSearching {
                ProgressView().scaleEffect(0.7)
            } else if !query.isEmpty {
                Button {
                    query = ""
                    onSubmit()
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct PopularSection: View {
    let title: String
    let items: [ModrinthProject]
    @ObservedObject var viewModel: LauncherViewModel
    let type: ModrinthProjectType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))

            if items.isEmpty {
                HStack {
                    ProgressView()
                    Text("Loading…")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(items) { project in
                        ProjectRow(project: project, viewModel: viewModel, type: type)
                    }
                }
            }
        }
    }
}

struct SearchResultsSection: View {
    let results: [ModrinthProject]
    @ObservedObject var viewModel: LauncherViewModel
    let type: ModrinthProjectType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if results.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("No results")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(results) { project in
                        ProjectRow(project: project, viewModel: viewModel, type: type)
                    }
                }
            }
        }
    }
}

struct ProjectRow: View {
    let project: ModrinthProject
    @ObservedObject var viewModel: LauncherViewModel
    let type: ModrinthProjectType
    @State private var isInstalling = false

    var body: some View {
        Button {
            install()
        } label: {
            HStack(spacing: 12) {
                // Icon placeholder (colored by project type)
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(typeColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: typeIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(typeColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(project.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(project.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isInstalling {
                    ProgressView().scaleEffect(0.75)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 10))
        .disabled(isInstalling)
    }

    private var typeColor: Color {
        switch type {
        case .mod: return .blue
        case .modpack: return .purple
        case .resourcepack: return .orange
        case .shader: return .teal
        }
    }

    private var typeIcon: String {
        switch type {
        case .mod: return "puzzlepiece.fill"
        case .modpack: return "square.stack.3d.up.fill"
        case .resourcepack: return "photo.fill"
        case .shader: return "sparkles"
        }
    }

    private func install() {
        isInstalling = true
        Task {
            await viewModel.install(projectSlug: project.slug, type: type)
            isInstalling = false
        }
    }
}

// MARK: - Installed Mods

struct InstalledModsSection: View {
    let instance: MinecraftInstance?
    @ObservedObject var viewModel: LauncherViewModel
    @State private var modFiles: [String] = []

    var body: some View {
        guard let instance else { return AnyView(EmptyView()) }

        let files = modFiles.sorted()
        guard !files.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("Installed Mods")
                    .font(.title3.weight(.semibold))

                LazyVStack(spacing: 2) {
                    ForEach(files, id: \.self) { file in
                        InstalledModRow(
                            fileName: file,
                            instance: instance,
                            viewModel: viewModel,
                            onToggle: { refresh(instance: instance) }
                        )
                    }
                }
            }
            .onAppear { refresh(instance: instance) }
        )
    }

    private func refresh(instance: MinecraftInstance) {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: instance.modsDirectory,
            includingPropertiesForKeys: nil
        )) ?? []
        modFiles = urls.map(\.lastPathComponent)
    }
}

struct InstalledModRow: View {
    let fileName: String
    let instance: MinecraftInstance
    @ObservedObject var viewModel: LauncherViewModel
    let onToggle: () -> Void

    var isEnabled: Bool { !fileName.hasSuffix(".disabled") }

    var displayName: String {
        fileName
            .replacingOccurrences(of: ".disabled", with: "")
            .replacingOccurrences(of: ".jar", with: "")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isEnabled ? "puzzlepiece.fill" : "puzzlepiece")
                .font(.system(size: 14))
                .foregroundStyle(isEnabled ? Color.blue : Color.secondary)
                .frame(width: 20)

            Text(displayName)
                .font(.subheadline)
                .foregroundStyle(isEnabled ? .primary : .secondary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    Task {
                        await viewModel.toggleMod(fileName: fileName, enabled: newValue)
                        onToggle()
                    }
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.mini)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
    }
}
