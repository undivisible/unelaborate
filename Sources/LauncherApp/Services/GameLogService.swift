import Foundation

actor GameLogService {
    private var logs: [UUID: [String]] = [:]

    func startCapture(instanceID: UUID, process: Process) {
        logs[instanceID] = []

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard let output = String(data: data, encoding: .utf8), !output.isEmpty else { return }
            Task {
                await self?.appendLog(instanceID: instanceID, output: output)
            }
        }
    }

    func appendLog(instanceID: UUID, output: String) {
        logs[instanceID, default: []].append(output)
    }

    func getLog(instanceID: UUID) -> [String] {
        logs[instanceID] ?? []
    }

    func clearLog(instanceID: UUID) {
        logs[instanceID] = []
    }
}
