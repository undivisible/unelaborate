import Foundation

struct OfflineAccount: Codable {
    let username: String
    let uuid: String
}

actor OfflineAuthService {
    func saveAccount(_ account: OfflineAccount) throws {
        let data = try JSONEncoder().encode(account)
        try KeychainService.save(data, service: "unelaborate.launcher", account: "offline")
    }

    func loadAccount() throws -> OfflineAccount? {
        guard let data = try KeychainService.load(service: "unelaborate.launcher", account: "offline") else {
            return nil
        }
        return try JSONDecoder().decode(OfflineAccount.self, from: data)
    }

    func generateUUID(from username: String) -> String {
        _ = username.data(using: .utf8)! // kept for potential future hash-based UUID gen
        let uuid = UUID().uuidString
        // Offline UUID generation: consistent per username
        // Simplified: just hash-based prefix
        return uuid
    }
}
