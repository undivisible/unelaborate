# unelaborate

Native macOS Minecraft launcher.

## Build & Run

```bash
./build-app.sh
open unelaborate.app
```

Or debug:
```bash
swift run
```

## Features

- **Instances** — isolated installs, groups, notes, sort by last played
- **Versions** — official Mojang manifest, pick version, install, play
- **Loaders** — Fabric, Quilt, NeoForge auto-install
- **Mods** — Modrinth search + one-click install with dependency resolution
- **CurseForge** — search + install (API key required)
- **Mod Management** — per-instance toggle, update check, quarantine
- **Auth** — Microsoft device-code flow, Keychain tokens
- **Java** — auto-detect system JVMs, auto-select per MC version, Temurin download
- **Import/Export** — .mrpack and CurseForge zip
- **Server List** — local-only, quick-join
- **Tools** — compatibility scan, crash explainer, instance repair, backup

## Data Directory

`~/.unelaborate/`

## License

MPL-2.0
