import Foundation

enum QueueState: String {
    case pending
    case downloading
    case verifying
    case linking
    case done
    case failed
    case rolledBack
}

struct InstallQueueItem: Identifiable {
    let id = UUID()
    let instanceID: UUID
    let projectSlug: String
    var targetType: ModrinthProjectType
    var state: QueueState = .pending
    var progress: Double = 0
    var error: String?
}
