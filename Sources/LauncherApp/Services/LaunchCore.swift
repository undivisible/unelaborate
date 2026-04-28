import Foundation

enum LaunchError: Error {
    case missingJava
    case missingClasspath
    case failedToReadVersionManifest
}

struct LaunchCore {
    func prepareLaunch(
        instance: MinecraftInstance,
        install: InstalledVersionArtifacts,
        authAccessToken: String,
        authUUID: String,
        username: String,
        userType: String = "msa"
    ) throws -> Process {
        let java = instance.javaPath ?? "/usr/bin/java"
        guard FileManager.default.fileExists(atPath: java) else {
            throw LaunchError.missingJava
        }

        let versionData = try Data(contentsOf: install.versionJSONPath)
        let versionManifest = try JSONDecoder().decode(MinecraftVersionManifest.self, from: versionData)

        let classpath = install.classpath.map(\.path).joined(separator: ":")
        guard !classpath.isEmpty else { throw LaunchError.missingClasspath }

        let nativesDir = instance.gameDirectory
            .appendingPathComponent("natives")
            .appendingPathComponent(instance.mcVersion)
        try FileManager.default.createDirectory(at: nativesDir, withIntermediateDirectories: true)

        var jvmArgs = resolveJVMArguments(from: versionManifest.arguments?.jvm ?? [], instance: instance, classpath: classpath, nativesDir: nativesDir)
        if jvmArgs.isEmpty {
            jvmArgs = instance.jvmArgs + ["-cp", classpath]
        }

        let gameArgs = resolveGameArguments(from: versionManifest, instance: instance, authAccessToken: authAccessToken, authUUID: authUUID, username: username, userType: userType, assetIndexID: install.assetIndexID)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: java)
        process.arguments = jvmArgs + [install.mainClass] + gameArgs
        process.currentDirectoryURL = instance.gameDirectory

        return process
    }

    private func resolveJVMArguments(from args: [VersionArgument], instance: MinecraftInstance, classpath: String, nativesDir: URL) -> [String] {
        var out: [String] = []
        for arg in args {
            switch arg {
            case let .string(value):
                out.append(replaceTokens(value, instance: instance, classpath: classpath, nativesDir: nativesDir, assetIndexID: instance.mcVersion, authAccessToken: "", authUUID: "", username: "", userType: "msa"))
            case let .rule(rule):
                guard rulesAllow(rule.rules) else { continue }
                switch rule.value {
                case let .string(v):
                    out.append(replaceTokens(v, instance: instance, classpath: classpath, nativesDir: nativesDir, assetIndexID: instance.mcVersion, authAccessToken: "", authUUID: "", username: "", userType: "msa"))
                case let .array(arr):
                    out.append(contentsOf: arr.map { replaceTokens($0, instance: instance, classpath: classpath, nativesDir: nativesDir, assetIndexID: instance.mcVersion, authAccessToken: "", authUUID: "", username: "", userType: "msa") })
                }
            }
        }
        return out
    }

    private func resolveGameArguments(from manifest: MinecraftVersionManifest, instance: MinecraftInstance, authAccessToken: String, authUUID: String, username: String, userType: String, assetIndexID: String) -> [String] {
        if let gameArgs = manifest.arguments?.game {
            var out: [String] = []
            for arg in gameArgs {
                switch arg {
                case let .string(value):
                    out.append(replaceTokens(value, instance: instance, classpath: "", nativesDir: instance.gameDirectory, assetIndexID: assetIndexID, authAccessToken: authAccessToken, authUUID: authUUID, username: username, userType: userType))
                case let .rule(rule):
                    guard rulesAllow(rule.rules) else { continue }
                    switch rule.value {
                    case let .string(v):
                        out.append(replaceTokens(v, instance: instance, classpath: "", nativesDir: instance.gameDirectory, assetIndexID: assetIndexID, authAccessToken: authAccessToken, authUUID: authUUID, username: username, userType: userType))
                    case let .array(arr):
                        out.append(contentsOf: arr.map { replaceTokens($0, instance: instance, classpath: "", nativesDir: instance.gameDirectory, assetIndexID: assetIndexID, authAccessToken: authAccessToken, authUUID: authUUID, username: username, userType: userType) })
                    }
                }
            }
            return out
        }

        if let legacy = manifest.minecraftArguments {
            return legacy
                .split(separator: " ")
                .map(String.init)
                .map { replaceTokens($0, instance: instance, classpath: "", nativesDir: instance.gameDirectory, assetIndexID: assetIndexID, authAccessToken: authAccessToken, authUUID: authUUID, username: username, userType: userType) }
        }

        return [
            "--username", username,
            "--version", instance.mcVersion,
            "--gameDir", instance.gameDirectory.path,
            "--assetsDir", instance.gameDirectory.appendingPathComponent("assets").path,
            "--assetIndex", assetIndexID,
            "--accessToken", authAccessToken,
            "--uuid", authUUID,
            "--userType", userType
        ]
    }

    private func replaceTokens(_ value: String, instance: MinecraftInstance, classpath: String, nativesDir: URL, assetIndexID: String, authAccessToken: String, authUUID: String, username: String, userType: String) -> String {
        value
            .replacingOccurrences(of: "${classpath}", with: classpath)
            .replacingOccurrences(of: "${natives_directory}", with: nativesDir.path)
            .replacingOccurrences(of: "${launcher_name}", with: "unelaborate")
            .replacingOccurrences(of: "${launcher_version}", with: "0.1")
            .replacingOccurrences(of: "${version_name}", with: instance.mcVersion)
            .replacingOccurrences(of: "${game_directory}", with: instance.gameDirectory.path)
            .replacingOccurrences(of: "${assets_root}", with: instance.gameDirectory.appendingPathComponent("assets").path)
            .replacingOccurrences(of: "${assets_index_name}", with: assetIndexID)
            .replacingOccurrences(of: "${auth_player_name}", with: username)
            .replacingOccurrences(of: "${auth_uuid}", with: authUUID)
            .replacingOccurrences(of: "${auth_access_token}", with: authAccessToken)
            .replacingOccurrences(of: "${auth_xuid}", with: "0")
            .replacingOccurrences(of: "${clientid}", with: "0")
            .replacingOccurrences(of: "${user_type}", with: userType)
            .replacingOccurrences(of: "${version_type}", with: "release")
            .replacingOccurrences(of: "${classpath_separator}", with: ":")
            .replacingOccurrences(of: "${library_directory}", with: instance.gameDirectory.appendingPathComponent("libraries").path)
    }

    private func rulesAllow(_ rules: [VersionRule]?) -> Bool {
        guard let rules, !rules.isEmpty else { return true }

        var allowed = false
        for rule in rules {
            let osMatch = rule.os?.name == nil || rule.os?.name == "osx"
            if osMatch {
                allowed = (rule.action == "allow")
            }
        }
        return allowed
    }
}
