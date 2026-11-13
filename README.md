# SZSIM

**Visual route simulator for the iOS Simulator.** A macOS app (developer tool)
where you mark points on a map, generate a route along the streets, and play the
trip back by sending coordinates to the simulator via `xcrun simctl location`.

Useful for testing location-dependent features (maps, geofencing, navigation,
tracking) without leaving your desk — with control over speed, movement profile,
and looped playback.

---

## Features

- 🗺️ **Interactive map** (native MapKit) — click to add points, or search an
  address / paste `lat, lon`.
- 🧭 **Street routing** (`MKDirections`) or **straight line** (geodesic).
- 📍 **Waypoints** origin (A) · stops (1, 2…) · destination (B), with distance and duration.
- ▶️ **Playback** with play/pause, progress slider, speed `0.5×–10×`, profile
  (Walk / Bike / Car) and looping. Changing speed/profile mid-playback continues
  from the current position.
- 📡 **Live telemetry**: latitude, longitude, speed, and heading.
- 💾 **Saved routes** (SwiftData): save, search, load (redraws from cache, no
  recompute), overwrite, and delete with confirmation.
- 🔁 **GPX**: import (GPX/KML) and export (`<trkpt>` with `<time>`), compatible with
  **Xcode** (Edit Scheme → Default Location) and **physical devices**.
- ⚙️ **Preferences**: send frequency (1–10 Hz) and default profile.
- ⌨️ **Shortcuts**: `Space` play/pause · `⌘R` back to start · `⌘,` preferences.

---

## Requirements

- **macOS 26.5+** (the configured deployment target; it can be lowered to
  macOS 14.0, the minimum for SwiftData and the modern SwiftUI `Map` API).
- **Xcode 16+** (the `simctl location` subcommand requires Xcode 14+).
- At least **one running iOS simulator** (*Booted* status).

> **About App Sandbox:** the project runs with **App Sandbox disabled** on
> purpose — it is required in order to run `/usr/bin/xcrun simctl` via `Process`.
> There are no special entitlements. "Sign to Run Locally" / Personal Team (free
> Apple ID) is enough; the project does not depend on a paid account.

---

## Build and run

```bash
# Build (Apple Silicon)
xcodebuild -scheme SZSIM -destination 'platform=macOS,arch=arm64' build

# Run the tests
xcodebuild test -scheme SZSIM -destination 'platform=macOS'
```

Or just open `SZSIM.xcodeproj` in Xcode and press **Run** (⌘R).

---

## How to use

1. **Boot an iOS simulator.** If none is *Booted*, the app shows the
   "No simulator running" screen with **Open Simulator** and **Refresh** buttons.
   From the terminal:
   ```bash
   xcrun simctl boot "iPhone 16 Pro"   # or open the Simulator app
   ```
   SZSIM detects it automatically (polling every 3 s).

2. **Select the simulator** at the top of the *Current route* tab (it shows the
   *Booted* status and the UDID).

3. **Mark the trip's points:**
   - click on the map, **or**
   - use the search field (address autocomplete, or paste `-23.5505, -46.6333`).

   The first point becomes the **origin (A)**, the last the **destination (B)**,
   and the ones in between **stops**.

4. **Choose the route mode** (*Follow streets* or *Straight line*) and the
   **profile** in the bottom bar. The route is drawn and the **Distance / Duration**
   cards appear.

5. **Play it back:** `Play` (or `Space`). The simulator's location pin starts
   moving along the route and the telemetry updates. Adjust the **speed**, enable
   **Loop**, or jump back to the start with `⌘R`.

6. **Confirm in the simulator:** open the iOS **Maps** app and watch the blue dot
   follow the trip.

### Saved routes

With a route built, click **Save route** and give it a name (it asks before
overwriting). In the **Saved** tab, click a route to load it (the map frames it
automatically) or use the 🗑 to delete it.

### GPX

- **Export GPX** produces a file compatible with Xcode (Edit Scheme → Options →
  Default Location) and physical devices.
- **Import GPX** accepts GPX/KML exported from other tools and loads it as a route.

### Preferences (⌘,)

- **Frequency** (1–10 Hz): how often the position is sent to the simulator —
  higher = smoother.
- **Default profile**: the profile used for new routes.

---

## Architecture

- **UI:** SwiftUI (MapKit's `Map`, `NavigationSplitView`).
- **Pattern:** MVVM with `@Observable` (Observation framework), `@MainActor` on the
  view models.
- **Persistence:** SwiftData (`SavedRoute`).
- **Map/search/routing:** native MapKit only (`MKLocalSearchCompleter`,
  `MKLocalSearch`, `MKDirections`) — no third-party SDKs, no API key.
- **Simulator integration:** `Process` running `xcrun simctl`, always using the
  selected UDID, off the main thread.

```
SZSIM/
  App/            # @main, ModelContainer, Settings scene
  Models/         # Waypoint, SavedRoute, RouteMode, MovementProfile, PlaybackSpeed,
                  # SimulatorDevice, RouteCoordinate
  Services/       # SimctlService, RouteBuilder, RouteSampler, PlaybackEngine,
                  # LocationSearchService, GPXService
  ViewModels/     # MainViewModel, SavedRoutesViewModel
  Views/          # Windows, Sidebar, Map, Playback, Sheets, EmptyStates,
                  # Preferences, Components (logo)
  Utilities/      # GeoMath, CoordinateParsing, PreferenceKey
  Extensions/
  Resources/      # Assets, Localizable.xcstrings
SZSIMTests/       # Swift Testing (61 tests)
```

The pure logic (geometry, resampling, playback engine, simctl and GPX parsing) is
covered by **61 tests** using the **Swift Testing** framework. `SimctlService` is
tested via a mock — the tests never actually run `xcrun`.

---

## Manual verification with the simulator

```bash
xcrun simctl list devices booted -j            # open simulators
xcrun simctl location <UDID> set -23.5505,-46.6333
xcrun simctl location <UDID> clear
```

---

## Notes

- Route simulation targets the **iOS Simulator**; physical devices via GPX (Default
  Location) or external tools.
- Cycling uses `.walking` as an approximation when computing street routes.
- Direct distribution, no notarization.
