import Foundation

enum CrashExplainer {
    static func explain(log: String) -> String {
        let lower = log.lowercased()

        if lower.contains("outofmemoryerror") {
            return "Java ran out of memory. Raise -Xmx or remove heavy shaders/mods."
        }
        if lower.contains("mixin apply failed") {
            return "Mixin failed. Mod version conflict likely. Update Fabric API and offending mod pair."
        }
        if lower.contains("nosuchmethoderror") || lower.contains("classnotfoundexception") {
            return "Missing or incompatible dependency. Reinstall mods with dependency resolver enabled."
        }
        if lower.contains("glfw error") || lower.contains("opengl") {
            return "Graphics stack issue. Disable shaders, update macOS, verify Java build supports Metal/GL path."
        }

        return "Unknown crash signature. Check latest.log + crash report, then isolate by binary-search disabling mods."
    }
}
