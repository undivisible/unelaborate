import Foundation

actor SystemJavaDetector {
    func detect() -> [JVMInstall] {
        var results: [JVMInstall] = []
        let jvmsDir = URL(fileURLWithPath: "/Library/Java/JavaVirtualMachines")
        guard let contents = try? FileManager.default.contentsOfDirectory(at: jvmsDir, includingPropertiesForKeys: nil) else {
            return []
        }

        for dir in contents {
            let javaBin = dir.appendingPathComponent("Contents/Home/bin/java")
            guard FileManager.default.fileExists(atPath: javaBin.path) else { continue }
            let name = dir.lastPathComponent.replacingOccurrences(of: ".jdk", with: "")
            let version = extractVersion(from: dir)
            results.append(JVMInstall(id: name, name: name, javaVersion: version, path: javaBin, isDefault: false))
        }

        return results
    }

    private func extractVersion(from path: URL) -> Int {
        let releaseFile = path.appendingPathComponent("Contents/Home/release")
        guard let content = try? String(contentsOf: releaseFile) else { return 0 }
        if let line = content.split(separator: "\n").first(where: { $0.hasPrefix("JAVA_VERSION=") }) {
            let versionString = line.replacingOccurrences(of: "JAVA_VERSION=\"", with: "").replacingOccurrences(of: "\"", with: "")
            let components = versionString.split(separator: ".")
            if components.count >= 2, let major = Int(components[0]), major == 1 {
                return Int(components[1]) ?? 0
            }
            return Int(components.first ?? "0") ?? 0
        }
        return 0
    }
}
