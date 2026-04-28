import Foundation

struct IncompatibilityFinding: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

enum IncompatibilityService {
    static func scan(modsDirectory: URL, loader: LoaderType) -> [IncompatibilityFinding] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: modsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        var findings: [IncompatibilityFinding] = []
        let names = files.map { $0.lastPathComponent.lowercased() }

        if names.contains(where: { $0.contains("optifine") }) && names.contains(where: { $0.contains("sodium") }) {
            findings.append(.init(title: "OptiFine with Sodium", detail: "Both present. Known render conflicts."))
        }

        if loader == .fabric && names.contains(where: { $0.contains("forge") || $0.contains("neoforge") }) {
            findings.append(.init(title: "Forge mod in Fabric instance", detail: "Loader mismatch detected by file name."))
        }

        if loader == .neoforge && names.contains(where: { $0.contains("fabric") || $0.contains("quilt") }) {
            findings.append(.init(title: "Fabric/Quilt mod in NeoForge instance", detail: "Loader mismatch detected by file name."))
        }

        return findings
    }
}
