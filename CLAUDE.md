# CLAUDE.md - SZSIM

## Project overview

- **Type**: macOS application (developer tool)
- **Language**: Swift 5 (language mode 5.0, with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- **UI Framework**: SwiftUI (AppKit only when there is no equivalent)
- **Deployment target**: macOS 26.5 (as configured; can be lowered to 14.0, the minimum for SwiftData and SwiftUI's modern `Map` API)
- **Xcode**: 16 or later (the `simctl location` subcommand requires Xcode 14+)
- **Distribution**: direct, no notarization (local build / "Sign to Run Locally")
- **Description**: a visual route simulator for the iOS Simulator. The user marks points on the map, the app generates the route along the streets (MapKit) and plays the trip back by sending coordinates to the simulator via `xcrun simctl location`. It supports saving, searching and loading routes, plus GPX import/export.
- **UI reference**: https://claude.ai/artifact/GhPjWBrRY2kifQMvKMN76S (main window + "no simulator" state)

## Architecture

### Stack
- **UI**: SwiftUI (MapKit's `Map` for SwiftUI, `NavigationSplitView`)
- **Architecture**: MVVM with `@Observable` (Observation framework)
- **Persistence**: SwiftData (saved routes)
- **Map, search and routing**: native MapKit only — `MKLocalSearchCompleter`, `MKLocalSearch`, `MKDirections`, `CLGeocoder`. No third-party SDKs or APIs, no API key.
- **Simulator integration**: `Process` running `/usr/bin/xcrun simctl ...`
- **Dependency injection**: SwiftUI `Environment` + protocols for the services

### Directory structure
```
SZSIM/
  App/                    # SZSIMApp (@main), ModelContainer setup, Settings scene
  Models/
    Waypoint.swift        # coordinate + kind (origin, stop, destination)
    SavedRoute.swift      # @Model SwiftData
    RouteCoordinate.swift # serializable coordinate (polyline cache)
    RouteMode.swift       # .streets (MKDirections) | .straight (straight line)
    MovementProfile.swift # walking 1.4 / cycling 5.5 / driving 13.9 m/s
    PlaybackSpeed.swift   # 0.5x, 1x, 2x, 5x, 10x
    SimulatorDevice.swift # UDID, name, runtime, state (decoded from the simctl JSON)
  Services/
    SimctlService.swift         # list simulators, set/clear location (SimctlRunning protocol)
    RouteBuilder.swift          # waypoints -> polyline (MKDirections or straight segments)
    RouteSampler.swift          # polyline resampling by speed + heading computation
    PlaybackEngine.swift        # play/pause/reset/loop, 1 Hz tick, current position
    LocationSearchService.swift # autocomplete + search (with debounce)
    GPXService.swift            # GPX import/export (with <time> per point)
  ViewModels/
    MainViewModel.swift
    SavedRoutesViewModel.swift
  Views/
    Windows/
      MainWindow.swift          # NavigationSplitView: sidebar + map + playback bar
    Sidebar/
      SidebarView.swift         # "Current route" | "Saved" tabs
      CurrentRouteView.swift    # simulator, route mode, points list, summary
      SavedRoutesView.swift     # search + saved routes list
    Map/
      RouteMapView.swift        # map, route, A/1/B markers, position marker with heading
      SearchFieldView.swift
      TelemetryCardView.swift   # lat, lon, speed, heading
    Playback/
      PlaybackBarView.swift     # play/pause, progress, speed, profile, loop
    Sheets/
      SaveRouteSheet.swift
    EmptyStates/
      NoSimulatorView.swift
    Preferences/
      SettingsView.swift        # send frequency, default profile
    Components/
      LogoMark.swift            # "Z route" logo (sidebar badge + app icon)
  Utilities/                    # GeoMath, CoordinateParsing, PreferenceKey
  Extensions/                   # MKPolyline+Coordinates
  Resources/                    # Assets, Localizable.xcstrings
SZSIMTests/                     # Swift Testing
```

## Domain rules

### Simulator integration
- List devices with `xcrun simctl list devices booted -j` and decode the JSON. Never parse the text output.
- Send the position with `xcrun simctl location <UDID> set <lat>,<lon>`, always using the selected UDID, never `booted` (there may be more than one simulator open).
- All `Process` calls are `async` and run off the main thread. Capture stderr and turn failures into `SimctlError`.
- Default send frequency: 1 Hz (configurable in Preferences). Do not exceed 10 Hz.
- On pause, the last position remains. When quitting the app or switching simulators, stop playback. `simctl location <UDID> clear` only on an explicit user action.
- If no simulator has Booted status, show `NoSimulatorView` and poll every 3 s (or provide a "Refresh" button).

### Routes and playback
- "Follow streets" mode: one `MKDirections` per pair of consecutive waypoints, concatenating the polylines. Cycling uses `.walking` as an approximation.
- "Straight line" mode: geodesic segments between the waypoints.
- `RouteSampler` resamples the polyline every `profileSpeed × multiplier × tickInterval` meters and computes the heading between consecutive points. It must be pure logic, no MapKit and no I/O, so it is testable.
- `PlaybackEngine` exposes progress (0–1), current position, heading, elapsed time and total duration. Changing speed or profile during playback continues from the current position.

### Search
- 300 ms debounce on `MKLocalSearchCompleter`. Never fire a search per keystroke.
- Honor Apple's "at the user's pace" model: no batched or looped searches or routing.

### Saved routes (SwiftData)
- `SavedRoute`: `id`, `name`, `waypoints`, `mode`, `profile`, `speed`, `polyline` (cached coordinates), `distanceMeters`, `createdAt`, `updatedAt`.
- Loading a saved route restores points, mode and profile and draws the cached polyline, **without calling `MKDirections` again**. Recompute only if the user edits the points.
- Saving with a name that already exists asks for overwrite confirmation. Deleting asks for confirmation.
- Search by name in the "Saved" tab. Each route can be exported as GPX.

### GPX
- Export `<wpt>` or `<trkpt>` with `<time>` computed from the profile speed (1×), so it also works in Xcode (Edit Scheme → Default Location) and on a physical device.
- Import GPX/KML exported from other tools. Without `<time>`, use the current profile.

## Conventions

### Code patterns
- Follow the Swift API Design Guidelines
- Swift concurrency (async/await) for all asynchronous code. Use `@MainActor` in view models.
- Prefer value types (struct, enum) over reference types (class)
- Declare access control (`private`, `internal`, `public`) explicitly
- `guard` for early returns, `if let` for optional binding
- User-visible text in English via String Catalog (`Localizable.xcstrings`)

### Naming
- **Types**: PascalCase (`SavedRoute`, `PlaybackEngine`)
- **Functions/properties**: camelCase (`setLocation(udid:coordinate:)`, `isPlaying`)
- **Protocols**: adjective or noun (`SimctlRunning`, `RouteBuilding`)
- **Views**: `View` suffix (`PlaybackBarView`)
- **ViewModels**: `ViewModel` suffix (`MainViewModel`)
- **Windows**: `Window` suffix (`MainWindow`)

### SwiftUI patterns for macOS
- `NavigationSplitView` for the sidebar + map layout
- `Settings` scene for Preferences (Cmd+,)
- `defaultSize(width: 1440, height: 900)` on the `WindowGroup`
- Keyboard shortcuts: Space = play/pause, Cmd+S = save route, Cmd+O = import GPX, Cmd+E = export GPX, Cmd+R = back to start
- Handle Cmd+Q, Cmd+W and Cmd+, correctly

### Error handling
- Domain-typed error enums: `SimctlError`, `RouteBuildError`, `GPXError`, `StorageError`
- `Result` for synchronous operations that can fail
- User-visible errors via SwiftUI's `.alert()`
- Logs with `os.Logger` (subsystem `com.szsim.app`, categories `simctl`, `playback`, `routing`, `storage`)

## Sandboxing and signing

- **App Sandbox**: **disabled** (required, because the app runs `xcrun simctl` via `Process`)
- **Hardened Runtime**: may stay enabled
- **Signing**: "Sign to Run Locally" or Personal Team (free Apple ID). **The project must not depend on a paid developer account.**
- **Entitlements**: none special; remove `com.apple.security.app-sandbox`
- **Permissions**:
  - Network (client): yes, for MapKit (outside the sandbox no entitlement is needed)
  - File access: via `NSOpenPanel`/`NSSavePanel` (GPX import/export)
  - Camera, Mac location: no

## Tests

- **Framework**: Swift Testing (`@Test`, `#expect`)
- Run all: Cmd+U in Xcode or `xcodebuild test -scheme SZSIM -destination 'platform=macOS'`
- Coverage priority: `RouteSampler` (distances, heading, resampling), `PlaybackEngine` (loop, pause, speed change mid-playback), `GPXService` (round-trip), decoding the `simctl` JSON
- `SimctlService` is tested via the `SimctlRunning` protocol with a mock. Tests never actually run `xcrun`.
- `@MainActor` on the suites that test view models

## Commands

### Build
```bash
# Build for macOS (Apple Silicon)
xcodebuild -scheme SZSIM -destination 'platform=macOS,arch=arm64' build

# Via XcodeBuildMCP (preferred with Claude Code)
# "Build SZSIM for macOS"
```

### Tests
```bash
xcodebuild test -scheme SZSIM -destination 'platform=macOS'
xcodebuild test -scheme SZSIM -only-testing:SZSIMTests/RouteSamplerTests -destination 'platform=macOS'
```

### Manual verification with the simulator
```bash
xcrun simctl list devices booted -j            # open simulators
xcrun simctl boot "iPhone 12"              # boot a simulator
xcrun simctl location <UDID> set -23.5505,-46.6333
xcrun simctl location <UDID> clear
```

### Distribution (no paid account)
```bash
# Local Release build
xcodebuild -scheme SZSIM -configuration Release -destination 'platform=macOS,arch=arm64' -derivedDataPath build

# Whoever receives the .app without notarization must remove the quarantine:
xattr -dr com.apple.quarantine "SZSIM.app"
```
Notarization (`notarytool`/`stapler`) is out of scope while there is no paid account.

### Code quality
```bash
swiftlint        # if installed
swiftformat .    # if installed
```

## MCP Servers

- **XcodeBuildMCP** (user/local): build, tests and project management
- **Serena** (user, optional): symbol navigation

## Important notes

- **Never edit the `.pbxproj` directly**: use XcodeBuildMCP or Xcode for project changes
- **Build destination**: always `platform=macOS,arch=arm64`. The app runs on the Mac, not on the iOS Simulator; the simulator is only the target of the coordinates.
- No external dependencies (no third-party SPM) until there is a clear need
- No Google Maps, Mapbox, Nominatim or OSRM: MapKit only
- MVP scope: map + waypoints + route via MKDirections + play/pause/speed + simulator selection + save/load routes. Physical device (pymobiledevice3), CLI and signal-loss simulation come later.
