import Foundation

enum ModrinthProjectType: String, Codable, CaseIterable {
    case mod
    case modpack
    case resourcepack
    case shader
}

struct ModrinthSearchResponse: Codable {
    let hits: [ModrinthProject]
}

struct ModrinthProject: Identifiable, Codable, Hashable {
    let slug: String
    let title: String
    let description: String
    let projectType: String
    let iconURL: String?
    let latestVersion: String?

    var id: String { slug }

    enum CodingKeys: String, CodingKey {
        case slug
        case title
        case description
        case projectType = "project_type"
        case iconURL = "icon_url"
        case latestVersion = "latest_version"
    }
}

struct ModrinthVersionResponse: Codable {
    let id: String
    let name: String
    let versionNumber: String
    let files: [ModrinthFile]
    let dependencies: [ModrinthDependency]
    let gameVersions: [String]
    let loaders: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case versionNumber = "version_number"
        case files
        case dependencies
        case gameVersions = "game_versions"
        case loaders
    }
}

struct ModrinthFile: Codable, Hashable {
    let url: String
    let filename: String
    let primary: Bool
    let hashes: [String: String]
}

struct ModrinthDependency: Codable, Hashable {
    let versionID: String?
    let projectID: String?
    let dependencyType: String

    enum CodingKeys: String, CodingKey {
        case versionID = "version_id"
        case projectID = "project_id"
        case dependencyType = "dependency_type"
    }
}
