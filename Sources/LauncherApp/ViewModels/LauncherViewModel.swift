import Foundation
import SwiftUI

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var instances: [MinecraftInstance] = []
    @Published var selectedInstance: MinecraftInstance?
    @Published var searchQuery = ""
    @Published var modSearchQuery = ""
    @Published var modrinthResults: [ModrinthProject] = []
    @Published var popularModpacks: [ModrinthProject] = []
    @Published var curseForgeResults: [CurseForgeMod] = []
    @Published var authMessage = "Not signed in"
    @Published var authCodeMessage = ""
    @Published var launchStatus = "Idle"
    @Published var currentAccount: LauncherAccount?
    @Published var isAuthenticated = false
    @Published var isOffline = false
    @Published var jvms: [JVMInstall] = []
    @Published var servers: [MinecraftServer] = []
    @Published var availableVersions: [String] = []
    @Published var showLogPanel = false
    @Published var instanceSort: InstanceSort = .lastPlayed
    @Published var userPresets: [UserPreset] = []
    @Published var isInstalling = false
    @Published var installedInstanceIDs: Set<UUID> = []
    @Published var gameLog: [String] = []
    @Published var crashExplanation = ""
    @Published var showCrashAlert = false
    @Published var feedbackMessage: String?
    @Published var popularMods: [ModrinthProject] = []
    @Published var popularResourcePacks: [ModrinthProject] = []
    @Published var popularShaders: [ModrinthProject] = []

    private let store = InstanceStore()
    private let modrinth = ModrinthClient()
    private let curseForge = CurseForgeClient()
    private let resolver: DependencyResolver
    private let installer = InstallQueueService()
    private let auth = MicrosoftAuthService()
    private let mcInstaller = MinecraftInstallService()
    private let loaderInstaller = LoaderInstallService()
    private let launchCore = LaunchCore()
    private let exporter = ModpackExportService()
    private let isolator = BrokenModIsolationService()
    private let jvmService = JVMDownloadService()
    private let serverService = ServerListService()
    private let importer = ModpackImportService()
    private let logService = GameLogService()
    private let javaSelector = JavaAutoSelectService()
    private let fabricInstaller = FabricInstaller()
    private let quiltInstaller = QuiltInstaller()
    private let neoforgeInstaller = NeoForgeInstaller()
    private let cfImporter = CurseForgeModpackImportService()
    private let backupService = InstanceBackupService()
    private let systemJava = SystemJavaDetector()
    private let presetStore = PresetStore()
    private let offlineAuth = OfflineAuthService()

    init() {
        self.resolver = DependencyResolver(client: modrinth)

        Task {
            await loadInstances()
            await loadStoredAccount()
            await loadJVMs()
            await loadServers()
            await loadVersions()
            await loadPresets()
            await loadPopularContent()
            checkInstalledInstances()
            startLogPolling()
        }
    }

    func checkInstalledInstances() {
        for instance in instances {
            let versionDir = instance.gameDirectory
                .appendingPathComponent("versions")
                .appendingPathComponent(instance.mcVersion)
            let jarPath = versionDir.appendingPathComponent("\(instance.mcVersion).jar")
            if FileManager.default.fileExists(atPath: jarPath.path) {
                installedInstanceIDs.insert(instance.id)
            }
        }
    }

    func loadInstances() async {
        do {
            instances = try await store.load()
            if selectedInstance == nil { selectedInstance = instances.first }
        } catch {
            instances = []
        }
    }

    func createInstance(name: String, version: String, loader: LoaderType, group: String = "Default", notes: String = "") async {
        do {
            var list = try await store.load()
            var instance = try await store.createInstance(name: name, version: version, loader: loader, group: group, notes: notes)
            let javaPath = await javaSelector.selectJavaPath(for: instance, available: jvms)
            instance.javaPath = javaPath
            list.append(instance)
            try await store.save(list)
            instances = list
            selectedInstance = instance
        } catch {}
    }

    func duplicateInstance(_ instance: MinecraftInstance) async {
        do {
            var list = try await store.load()
            let copy = try await store.createInstance(
                name: "\(instance.name) Copy",
                version: instance.mcVersion,
                loader: instance.loader,
                group: instance.group,
                notes: instance.notes
            )
            list.append(copy)
            try await store.save(list)
            instances = list
            selectedInstance = copy
        } catch {}
    }

    func saveSelectedInstance() async {
        guard let selected = selectedInstance else { return }
        do {
            var list = try await store.load()
            guard let idx = list.firstIndex(where: { $0.id == selected.id }) else { return }
            list[idx] = selected
            try await store.save(list)
            instances = list
        } catch {}
    }

    func deleteInstance(_ instance: MinecraftInstance) async {
        do {
            var list = try await store.load()
            list.removeAll(where: { $0.id == instance.id })
            try await store.save(list)
            if selectedInstance?.id == instance.id {
                selectedInstance = list.first
            }
            instances = list
            installedInstanceIDs.remove(instance.id)
            try? FileManager.default.removeItem(at: instance.gameDirectory)
        } catch {}
    }

    func beginMicrosoftLogin() async {
        do {
            let code = try await auth.beginDeviceCode()
            authCodeMessage = code.message
            let token = try await auth.pollForToken(deviceCode: code.deviceCode, interval: code.interval)
            let account = try await auth.authenticateMinecraft(msToken: token)
            try await auth.saveAccount(account)
            currentAccount = account
            isAuthenticated = true
            isOffline = false
            authMessage = "Signed in as \(account.username)"
        } catch {
            authMessage = "Login failed"
        }
    }

    func loginOffline(username: String) async {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let account = OfflineAccount(username: trimmed, uuid: UUID().uuidString)
        do {
            try await offlineAuth.saveAccount(account)
            currentAccount = LauncherAccount(
                accessToken: "",
                refreshToken: nil,
                expiresAt: .distantFuture,
                username: trimmed,
                uuid: account.uuid
            )
            isAuthenticated = true
            isOffline = true
            authMessage = "Offline: \(trimmed)"
        } catch {
            authMessage = "Offline login failed"
        }
    }

    func loadStoredAccount() async {
        do {
            if let account = try await auth.loadAccount(), account.expiresAt > Date() {
                currentAccount = account
                isAuthenticated = true
                isOffline = false
                authMessage = "Signed in as \(account.username)"
                return
            }
        } catch {}

        do {
            if let offline = try await offlineAuth.loadAccount() {
                currentAccount = LauncherAccount(
                    accessToken: "",
                    refreshToken: nil,
                    expiresAt: .distantFuture,
                    username: offline.username,
                    uuid: offline.uuid
                )
                isAuthenticated = true
                isOffline = true
                authMessage = "Offline: \(offline.username)"
            }
        } catch {}
    }

    func signOut() async {
        do {
            try KeychainService.save(Data(), service: "unelaborate.launcher", account: "default")
            try KeychainService.save(Data(), service: "unelaborate.launcher", account: "offline")
        } catch {}
        currentAccount = nil
        isAuthenticated = false
        isOffline = false
        authMessage = "Not signed in"
    }

    func installOrPlay() async {
        guard let instance = selectedInstance else { return }
        if installedInstanceIDs.contains(instance.id) {
            await launchSelectedInstance()
        } else {
            await installSelectedMinecraftVersion()
        }
    }

    func installSelectedMinecraftVersion() async {
        guard var instance = selectedInstance else { return }
        isInstalling = true
        do {
            launchStatus = "Installing \(instance.mcVersion)"
            _ = try await mcInstaller.installVersion(instance.mcVersion, instance: instance)

            if instance.loader != .vanilla {
                let result = try await loaderInstaller.install(loader: instance.loader, mcVersion: instance.mcVersion)
                instance.loaderVersion = result.loaderVersion
                selectedInstance = instance
                await saveSelectedInstance()

                switch instance.loader {
                case .fabric:
                    try await fabricInstaller.install(mcVersion: instance.mcVersion, loaderVersion: result.loaderVersion, into: instance)
                case .quilt:
                    try await quiltInstaller.install(mcVersion: instance.mcVersion, loaderVersion: result.loaderVersion, into: instance)
                case .neoforge:
                    if let version = instance.loaderVersion {
                        try await neoforgeInstaller.install(version: version, mcVersion: instance.mcVersion, into: instance)
                    }
                case .vanilla:
                    break
                }
            }
            installedInstanceIDs.insert(instance.id)
            launchStatus = "Ready to play"
            showFeedback("Installed successfully")
        } catch {
            launchStatus = "Install failed: \(error.localizedDescription)"
            showFeedback("Install failed")
        }
        isInstalling = false
    }

    func launchSelectedInstance() async {
        guard let instance = selectedInstance else { return }
        guard let account = currentAccount else {
            launchStatus = "Login required"
            return
        }

        do {
            launchStatus = "Preparing launch"
            let versionID = effectiveVersionID(for: instance)
            let install = try await mcInstaller.installVersion(versionID, instance: instance)
            let process = try launchCore.prepareLaunch(
                instance: instance,
                install: install,
                authAccessToken: account.accessToken,
                authUUID: account.uuid,
                username: account.username
            )
            await logService.startCapture(instanceID: instance.id, process: process)
            try process.run()
            launchStatus = "Game started"
            showFeedback("Game started")
            showLogPanel = true
            let startTime = Date()
            var updated = instance
            updated.lastPlayed = startTime
            selectedInstance = updated
            await saveSelectedInstance()

            Task {
                process.waitUntilExit()
                let duration = Date().timeIntervalSince(startTime)
                await MainActor.run {
                    if var inst = self.selectedInstance, inst.id == instance.id {
                        inst.totalPlayTime += duration
                        self.selectedInstance = inst
                        Task { await self.saveSelectedInstance() }
                    }
                    self.launchStatus = "Game exited (\(Int(duration))s)"
                }
            }
        } catch {
            launchStatus = "Launch failed: \(error.localizedDescription)"
        }
    }

    func loadVersions() async {
        do {
            let versions = try await mcInstaller.listVersions()
            availableVersions = versions.filter { $0.type == "release" }.map(\.id)
        } catch {
            availableVersions = []
        }
    }

    func loadPopularContent() async {
        async let modpacksTask = modrinth.getFeatured(type: .modpack)
        async let modsTask = modrinth.getFeatured(type: .mod)
        async let resourcePacksTask = modrinth.getFeatured(type: .resourcepack)
        async let shadersTask = modrinth.getFeatured(type: .shader)
        popularModpacks = (try? await modpacksTask) ?? []
        popularMods = (try? await modsTask) ?? []
        popularResourcePacks = (try? await resourcePacksTask) ?? []
        popularShaders = (try? await shadersTask) ?? []
    }

    func showFeedback(_ message: String) {
        feedbackMessage = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            feedbackMessage = nil
        }
    }

    func searchModrinthResults(query: String, type: ModrinthProjectType) async throws -> [ModrinthProject] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return try await modrinth.search(
            query: query,
            type: type,
            loader: selectedInstance?.loader,
            gameVersion: selectedInstance?.mcVersion
        )
    }

    func startLogPolling() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let instance = self.selectedInstance else { return }
                let log = await self.logService.getLog(instanceID: instance.id)
                self.gameLog = log

                // Auto-detect crash and show non-blocking notification
                let fullLog = log.joined()
                if fullLog.contains("CRASH") || fullLog.contains("Exception") || fullLog.contains("Error") {
                    let explanation = CrashExplainer.explain(log: fullLog)
                    if explanation != self.crashExplanation {
                        self.crashExplanation = explanation
                        self.showFeedback("Crash: \(explanation)")
                    }
                }
            }
        }
    }

    private func effectiveVersionID(for instance: MinecraftInstance) -> String {
        guard let loaderVersion = instance.loaderVersion else { return instance.mcVersion }
        switch instance.loader {
        case .fabric:
            return "fabric-loader-\(loaderVersion)-\(instance.mcVersion)"
        case .quilt:
            return "quilt-loader-\(loaderVersion)-\(instance.mcVersion)"
        case .neoforge:
            return instance.mcVersion
        case .vanilla:
            return instance.mcVersion
        }
    }

    func loadJVMs() async {
        do {
            var installed = try await jvmService.listInstalled()
            let system = await systemJava.detect()
            installed.append(contentsOf: system)
            jvms = installed
        } catch {
            jvms = await systemJava.detect()
        }
    }

    func installJVM(version: Int) async {
        do {
            let jvm = try await jvmService.installTemurin(version: version)
            jvms.append(jvm)
        } catch {}
    }

    func loadServers() async {
        do {
            servers = try await serverService.load()
        } catch {
            servers = []
        }
    }

    func saveServers() async {
        do {
            try await serverService.save(servers)
        } catch {}
    }

    func importMrpack(from url: URL) async {
        do {
            let instance = try await importer.importMrpack(from: url, into: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".unelaborate"))
            var list = try await store.load()
            list.append(instance)
            try await store.save(list)
            instances = list
            selectedInstance = instance
        } catch {}
    }

    func importCurseForgeZip(from url: URL) async {
        do {
            let instance = try await cfImporter.importZip(from: url, into: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".unelaborate"))
            var list = try await store.load()
            list.append(instance)
            try await store.save(list)
            instances = list
            selectedInstance = instance
        } catch {}
    }

    func searchModrinth(type: ModrinthProjectType? = nil) async {
        guard !modSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            modrinthResults = []
            return
        }
        do {
            modrinthResults = try await modrinth.search(
                query: modSearchQuery,
                type: type,
                loader: selectedInstance?.loader,
                gameVersion: selectedInstance?.mcVersion
            )
        } catch {
            modrinthResults = []
        }
    }

    func searchCurseForge() async {
        guard let instance = selectedInstance else { return }
        guard !modSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            curseForgeResults = []
            return
        }

        do {
            curseForgeResults = try await curseForge.searchMods(query: modSearchQuery, gameVersion: instance.mcVersion)
        } catch {
            curseForgeResults = []
        }
    }

    func installCurseForge(mod: CurseForgeMod) async {
        guard let instance = selectedInstance else { return }
        do {
            let files = try await curseForge.files(for: mod.id, gameVersion: instance.mcVersion)
            guard let best = files.first, let url = best.downloadURL else {
                throw NSError(domain: "CurseForge", code: 404)
            }

            let expectedSha1 = best.hashes?.first(where: { $0.algo == 1 })?.value
            let resolved = ResolvedInstall(
                projectSlug: mod.slug,
                version: ModrinthVersionResponse(
                    id: String(best.id),
                    name: best.fileName,
                    versionNumber: String(best.id),
                    files: [ModrinthFile(url: url, filename: best.fileName, primary: true, hashes: ["sha1": expectedSha1 ?? ""])],
                    dependencies: [],
                    gameVersions: [instance.mcVersion],
                    loaders: [instance.loader.rawValue]
                ),
                file: ModrinthFile(url: url, filename: best.fileName, primary: true, hashes: ["sha1": expectedSha1 ?? ""]),
                type: .mod
            )

            try await installer.install(resolved: [resolved], into: instance)
        } catch {
            launchStatus = "Install failed"
        }
    }

    func install(projectSlug: String, type: ModrinthProjectType) async {
        guard let instance = selectedInstance else { return }
        do {
            let resolved = try await resolver.resolve(
                projectSlug: projectSlug,
                type: type,
                loader: instance.loader,
                gameVersion: instance.mcVersion
            )
            try await installer.install(resolved: resolved, into: instance)

            if type == .mod {
                var updated = instance
                updated.enabledMods.formUnion(resolved.map(\.projectSlug))
                selectedInstance = updated
                await saveSelectedInstance()
            }
            showFeedback("Installed \(projectSlug)")
        } catch {
            launchStatus = "Install failed"
            showFeedback("Install failed")
        }
    }

    func exportSelectedInstance() async {
        guard let instance = selectedInstance else { return }
        do {
            let destination = instance.gameDirectory.appendingPathComponent(instance.name)
            try await exporter.exportMrpack(instance: instance, destination: destination)
            launchStatus = "Exported .mrpack"
        } catch {
            launchStatus = "Export failed"
        }
    }

    func backupSelectedInstance() async {
        guard let instance = selectedInstance else { return }
        do {
            _ = try await backupService.backup(instance: instance)
            launchStatus = "Backup created"
        } catch {
            launchStatus = "Backup failed"
        }
    }

    func launchWithServer(_ server: MinecraftServer) async {
        guard let instance = selectedInstance else { return }
        guard let account = currentAccount else {
            launchStatus = "Login required"
            return
        }

        do {
            launchStatus = "Preparing launch"
            let versionID = effectiveVersionID(for: instance)
            let install = try await mcInstaller.installVersion(versionID, instance: instance)
            let process = try launchCore.prepareLaunch(
                instance: instance,
                install: install,
                authAccessToken: account.accessToken,
                authUUID: account.uuid,
                username: account.username
            )
            process.arguments?.append(contentsOf: ["--server", server.address, "--port", String(server.port)])
            await logService.startCapture(instanceID: instance.id, process: process)
            try process.run()
            launchStatus = "Joining \(server.name)"
            showLogPanel = true
            let startTime = Date()
            var updated = instance
            updated.lastPlayed = startTime
            selectedInstance = updated
            await saveSelectedInstance()

            Task {
                process.waitUntilExit()
                let duration = Date().timeIntervalSince(startTime)
                await MainActor.run {
                    if var inst = self.selectedInstance, inst.id == instance.id {
                        inst.totalPlayTime += duration
                        self.selectedInstance = inst
                        Task { await self.saveSelectedInstance() }
                    }
                    self.launchStatus = "Game exited (\(Int(duration))s)"
                }
            }
        } catch {
            launchStatus = "Launch failed: \(error.localizedDescription)"
        }
    }

    func isolateBrokenMods() async {
        guard let instance = selectedInstance else { return }
        do {
            _ = try await isolator.isolateAllMods(instance: instance, reason: "manual")
            launchStatus = "Moved mods to quarantine"
        } catch {
            launchStatus = "Isolation failed"
        }
    }

    func toggleMod(fileName: String, enabled: Bool) async {
        guard let instance = selectedInstance else { return }
        let target = instance.modsDirectory.appendingPathComponent(fileName)

        if enabled, fileName.hasSuffix(".disabled") {
            let restored = instance.modsDirectory.appendingPathComponent(fileName.replacingOccurrences(of: ".disabled", with: ""))
            try? FileManager.default.moveItem(at: target, to: restored)
        } else if !enabled, !fileName.hasSuffix(".disabled") {
            let disabled = instance.modsDirectory.appendingPathComponent(fileName + ".disabled")
            try? FileManager.default.moveItem(at: target, to: disabled)
        }
    }

    func clearLog() async {
        guard let instance = selectedInstance else { return }
        await logService.clearLog(instanceID: instance.id)
        gameLog = []
        crashExplanation = ""
        showCrashAlert = false
    }

    func loadPresets() async {
        do {
            userPresets = try await presetStore.load()
        } catch {
            userPresets = []
        }
    }

    func savePresets() async {
        do {
            try await presetStore.save(userPresets)
        } catch {}
    }

    func createPreset(name: String, description: String, slugs: [String]) async {
        userPresets.append(UserPreset(name: name, description: description, projectSlugs: slugs))
        await savePresets()
    }

    func deletePreset(_ preset: UserPreset) async {
        userPresets.removeAll(where: { $0.id == preset.id })
        await savePresets()
    }

    func applyPreset(_ preset: UserPreset) async {
        for slug in preset.projectSlugs {
            await install(projectSlug: slug, type: .mod)
        }
    }

    func exportPreset(_ preset: UserPreset, to destination: URL) {
        do {
            let data = try JSONEncoder.pretty.encode(preset)
            try data.write(to: destination.appendingPathExtension("json"), options: .atomic)
        } catch {}
    }

    func importPreset(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let preset = try JSONDecoder().decode(UserPreset.self, from: data)
            userPresets.append(preset)
            await savePresets()
        } catch {}
    }

    var filteredInstances: [MinecraftInstance] {
        guard !searchQuery.isEmpty else { return instances }
        return instances.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.mcVersion.localizedCaseInsensitiveContains(searchQuery) ||
            $0.loader.rawValue.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var groupedInstances: [String: [MinecraftInstance]] {
        let sorted = filteredInstances.sorted {
            switch instanceSort {
            case .name: return $0.name < $1.name
            case .lastPlayed: return ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast)
            case .version: return $0.mcVersion > $1.mcVersion
            }
        }
        return Dictionary(grouping: sorted, by: { $0.group })
    }
}

enum InstanceSort: String, CaseIterable {
    case lastPlayed = "Last Played"
    case name = "Name"
    case version = "Version"
}
