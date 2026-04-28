# unelaborate — Agent Guide

## Build
```bash
brisk build          # debug
./build-app.sh       # release app bundle
```

## Architecture
- SwiftUI + AppKit where needed
- Async/await URLSession for all networking
- Actors for thread-safe services
- Keychain for auth tokens
- FileManager + bookmarks for paths

## Key Files
- `LauncherApp.swift` — App entry, window config
- `ViewModels/LauncherViewModel.swift` — Main app state
- `Services/` — All business logic
- `Models/` — Data types
- `Views/` — SwiftUI views

## Services
- `MicrosoftAuthService` — MS → Xbox → XSTS → MC
- `MinecraftInstallService` — Official manifest, libraries, assets
- `FabricInstaller` / `QuiltInstaller` / `NeoForgeInstaller`
- `ModrinthClient` — Search + version API
- `CurseForgeClient` — Search + files API
- `DependencyResolver` — Recursive Modrinth deps
- `InstallQueueService` — Download + cache + link
- `SharedCacheService` — Symlink/hardlink cache
- `LaunchCore` — Process spawn with classpath + args
- `JVMDownloadService` — Temurin download
- `SystemJavaDetector` — Scan `/Library/Java/JavaVirtualMachines`
- `JavaAutoSelectService` — Pick Java for MC version
- `GameLogService` — stdout/stderr capture
- `ModUpdateChecker` — Check Modrinth for updates
- `InstanceRepairService` — Validate files
- `BrokenModIsolationService` — Quarantine mods
- `ModpackExportService` / `ModpackImportService` / `CurseForgeModpackImportService`
- `InstanceBackupService`
- `ServerListService`
- `ConfigService`
- `InstanceStore`

## Notes
- MPL-2.0 license
- macOS 14+ required
- CurseForge requires API key in Settings or `CURSEFORGE_API_KEY` env
- No GPL code copied
