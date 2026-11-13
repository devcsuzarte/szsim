# Gotchas — SZSIM

Patterns that have already broken the build, turned into hard rules so we don't
repeat them.

## 1. Parameter default value calling a `@MainActor` init

`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` makes almost every type MainActor-isolated.
**Parameter default-value expressions** are evaluated in a *nonisolated* context, so:

```swift
init(playback: PlaybackEngine = PlaybackEngine()) // ERROR: @MainActor init in a nonisolated context
```

**Rule:** for dependencies of `@MainActor` types, use `nil` as the default and build
them in the init body (which is MainActor-isolated):

```swift
init(playback: PlaybackEngine? = nil) {
    self.playback = playback ?? PlaybackEngine()
}
```

The same applies to default parameter values in test helper functions — use `nil`
and resolve them in the body. Plain value types (e.g. the `SimctlService`,
`RouteBuilder` structs) did not trigger the error; only the `@Observable final class` ones.

## 2. MapKit internal logs in the console (ignore)

With MapKit's `Map`, these logs appear and are **benign system noise**, not our bugs:

- `Failed to locate resource named "default.csv"`
- `Wrapped around the polygon without finishing... :-(` / `List has N nodes:` / `Building failed to triangulate!` (triangulating a tile's 3D buildings)
- `CAMetalLayer ignoring invalid setDrawableSize width=0 height=0` (transient during layout)

**Rule:** don't try to "fix" them — they don't come from our code and you can't
silence system logs. Only investigate if there's a VISIBLE symptom (gray/white map,
not rendering). Confirmed on 2026-11-13 that the app works fine with these logs present.
