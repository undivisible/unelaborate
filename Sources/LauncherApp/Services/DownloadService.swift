import CryptoKit
import Foundation

enum DownloadError: Error {
    case invalidURL
    case hashMismatch
    case cancelled
}

struct DownloadProgress {
    let projectSlug: String
    let progress: Double
    let status: String
}

actor DownloadService {
    private let session: URLSession
    private var activeDownloads: [String: Task<Void, Never>] = [:]
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 8
        self.session = URLSession(configuration: config)
    }
    
    func download(
        url: String,
        expectedSha1: String?,
        into directory: URL,
        progressCallback: @escaping (Double, String) -> Void
    ) async throws -> URL {
        guard let remote = URL(string: url) else { throw DownloadError.invalidURL }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let local = directory.appendingPathComponent(remote.lastPathComponent)

        progressCallback(0.1, "Downloading…")
        var req = URLRequest(url: remote)
        req.addValue("unelaborate-launcher/0.1", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: req)
        progressCallback(0.9, "Verifying…")

        if let expectedSha1, !expectedSha1.isEmpty {
            let digest = Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard digest == expectedSha1.lowercased() else { throw DownloadError.hashMismatch }
        }

        try data.write(to: local, options: Data.WritingOptions.atomic)
        progressCallback(1.0, "Done")
        return local
    }
    
    func cancelDownload(for slug: String) {
        activeDownloads[slug]?.cancel()
        activeDownloads[slug] = nil
    }
}
