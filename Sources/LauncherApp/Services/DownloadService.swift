import CryptoKit
import Foundation

enum DownloadError: Error {
    case invalidURL
    case hashMismatch
}

actor DownloadService {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 8
        self.session = URLSession(configuration: config)
    }

    func download(url: String, expectedSha1: String?, into directory: URL) async throws -> URL {
        guard let remote = URL(string: url) else { throw DownloadError.invalidURL }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let local = directory.appendingPathComponent(remote.lastPathComponent)
        let (data, _) = try await session.data(from: remote)

        if let expectedSha1, !expectedSha1.isEmpty {
            let digest = Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard digest == expectedSha1.lowercased() else {
                throw DownloadError.hashMismatch
            }
        }

        try data.write(to: local, options: .atomic)
        return local
    }
}
