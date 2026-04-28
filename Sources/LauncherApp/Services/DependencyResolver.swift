import Foundation

struct ResolvedInstall {
    let projectSlug: String
    let version: ModrinthVersionResponse
    let file: ModrinthFile
    let type: ModrinthProjectType
}

actor DependencyResolver {
    private let client: ModrinthClient

    init(client: ModrinthClient) {
        self.client = client
    }

    func resolve(projectSlug: String, type: ModrinthProjectType, loader: LoaderType, gameVersion: String) async throws -> [ResolvedInstall] {
        var seen = Set<String>()
        var output: [ResolvedInstall] = []
        try await resolveRecursive(projectSlug: projectSlug, type: type, loader: loader, gameVersion: gameVersion, seen: &seen, output: &output)
        return output
    }

    private func resolveRecursive(projectSlug: String, type: ModrinthProjectType, loader: LoaderType, gameVersion: String, seen: inout Set<String>, output: inout [ResolvedInstall]) async throws {
        guard !seen.contains(projectSlug) else { return }
        seen.insert(projectSlug)

        let versions = try await client.versions(for: projectSlug, loader: loader, gameVersion: gameVersion)
        guard let best = versions.first, let primary = best.files.first(where: { $0.primary }) ?? best.files.first else {
            return
        }

        output.append(.init(projectSlug: projectSlug, version: best, file: primary, type: type))

        for dep in best.dependencies where dep.dependencyType == "required" {
            guard let dependencySlug = dep.projectID else { continue }
            try await resolveRecursive(projectSlug: dependencySlug, type: .mod, loader: loader, gameVersion: gameVersion, seen: &seen, output: &output)
        }
    }
}
