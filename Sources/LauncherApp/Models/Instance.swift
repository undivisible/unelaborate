import Foundation

enum LoaderType: String, Codable, CaseIterable, Identifiable {
    case vanilla
    case fabric
    case quilt
    case neoforge

    var id: String { rawValue }
}

struct MinecraftInstance: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var mcVersion: String
    var loader: LoaderType
    var loaderVersion: String?
    var javaPath: String?
    var jvmArgs: [String]
    var gameDirectory: URL
    var modsDirectory: URL
    var resourcePackDirectory: URL
    var shaderDirectory: URL
    var enabledMods: Set<String>
    var notes: String
    var group: String
    var iconName: String?
    var lastPlayed: Date?
    var totalPlayTime: TimeInterval

    init(
        id: UUID = UUID(),
        name: String,
        mcVersion: String,
        loader: LoaderType,
        loaderVersion: String? = nil,
        javaPath: String? = nil,
        jvmArgs: [String] = ["-Xms2G", "-Xmx6G"],
        gameDirectory: URL,
        modsDirectory: URL,
        resourcePackDirectory: URL,
        shaderDirectory: URL,
        enabledMods: Set<String> = [],
        notes: String = "",
        group: String = "Default",
        iconName: String? = nil,
        lastPlayed: Date? = nil,
        totalPlayTime: TimeInterval = 0
    ) {
        self.id = id
        self.name = name
        self.mcVersion = mcVersion
        self.loader = loader
        self.loaderVersion = loaderVersion
        self.javaPath = javaPath
        self.jvmArgs = jvmArgs
        self.gameDirectory = gameDirectory
        self.modsDirectory = modsDirectory
        self.resourcePackDirectory = resourcePackDirectory
        self.shaderDirectory = shaderDirectory
        self.enabledMods = enabledMods
        self.notes = notes
        self.group = group
        self.iconName = iconName
        self.lastPlayed = lastPlayed
        self.totalPlayTime = totalPlayTime
    }
}
