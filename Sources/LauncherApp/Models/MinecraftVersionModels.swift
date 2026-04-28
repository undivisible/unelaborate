import Foundation

struct VersionManifestIndex: Codable {
    let latest: LatestVersions
    let versions: [VersionManifestEntry]
}

struct LatestVersions: Codable {
    let release: String
    let snapshot: String
}

struct VersionManifestEntry: Codable {
    let id: String
    let type: String
    let url: String
    let time: String
    let releaseTime: String

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case url
        case time
        case releaseTime = "releaseTime"
    }
}

struct MinecraftVersionManifest: Codable {
    let id: String
    let mainClass: String
    let arguments: VersionArguments?
    let minecraftArguments: String?
    let libraries: [VersionLibrary]
    let assetIndex: VersionAssetIndex
    let downloads: VersionDownloads

    enum CodingKeys: String, CodingKey {
        case id
        case mainClass = "mainClass"
        case arguments
        case minecraftArguments = "minecraftArguments"
        case libraries
        case assetIndex
        case downloads
    }
}

struct VersionArguments: Codable {
    let game: [VersionArgument]
    let jvm: [VersionArgument]
}

enum VersionArgument: Codable {
    case string(String)
    case rule(VersionRuleArgument)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }
        self = .rule(try container.decode(VersionRuleArgument.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .rule(value):
            try container.encode(value)
        }
    }
}

struct VersionRuleArgument: Codable {
    let rules: [VersionRule]?
    let value: RuleValue
}

struct VersionRule: Codable {
    let action: String
    let os: VersionRuleOS?
}

struct VersionRuleOS: Codable {
    let name: String?
}

enum RuleValue: Codable {
    case string(String)
    case array([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }
        self = .array(try container.decode([String].self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        }
    }
}

struct VersionLibrary: Codable {
    let name: String
    let downloads: LibraryDownloads?
    let rules: [VersionRule]?
    let natives: [String: String]?
}

struct LibraryDownloads: Codable {
    let artifact: LibraryArtifact?
    let classifiers: [String: LibraryArtifact]?
}

struct LibraryArtifact: Codable {
    let path: String
    let sha1: String
    let size: Int
    let url: String
}

struct VersionAssetIndex: Codable {
    let id: String
    let sha1: String
    let size: Int
    let totalSize: Int
    let url: String
}

struct VersionDownloads: Codable {
    let client: VersionDownloadArtifact
}

struct VersionDownloadArtifact: Codable {
    let sha1: String
    let size: Int
    let url: String
}

struct AssetIndexManifest: Codable {
    let objects: [String: AssetObject]
}

struct AssetObject: Codable {
    let hash: String
    let size: Int
}
