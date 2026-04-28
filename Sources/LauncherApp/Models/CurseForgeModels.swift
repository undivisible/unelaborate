import Foundation

struct CurseForgeSearchResponse: Codable {
    let data: [CurseForgeMod]
}

struct CurseForgeMod: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let summary: String
    let slug: String
    let links: CurseForgeLinks?
    let latestFilesIndexes: [CurseForgeLatestFileIndex]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case summary
        case slug
        case links
        case latestFilesIndexes = "latestFilesIndexes"
    }
}

struct CurseForgeLinks: Codable, Hashable {
    let websiteUrl: String?
}

struct CurseForgeLatestFileIndex: Codable, Hashable {
    let gameVersion: String
    let modLoader: Int?
    let filename: String
    let fileId: Int

    enum CodingKeys: String, CodingKey {
        case gameVersion
        case modLoader
        case filename
        case fileId
    }
}

struct CurseForgeFilesResponse: Codable {
    let data: [CurseForgeFile]
}

struct CurseForgeFile: Codable, Hashable {
    let id: Int
    let fileName: String
    let downloadURL: String?
    let hashes: [CurseForgeFileHash]?

    enum CodingKeys: String, CodingKey {
        case id
        case fileName
        case downloadURL = "downloadUrl"
        case hashes
    }
}

struct CurseForgeFileHash: Codable, Hashable {
    let value: String
    let algo: Int
}
