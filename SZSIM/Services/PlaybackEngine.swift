//
//  PlaybackEngine.swift
//  SZSIM
//

import Foundation

/// The trip playback engine.
///
/// Works in arc length (`distanceCovered`, meters) instead of sample indices, so
/// that changing speed or profile mid-playback continues from the current
/// position. `tick()` is the pure unit of advancement; its caller (the view model)
/// sets the frequency (1 Hz by default, configurable up to 10 Hz).
@MainActor
@Observable
final class PlaybackEngine {
    var profile: MovementProfile
    var speed: PlaybackSpeed
    var loops: Bool
    /// Interval between ticks (= 1 / send frequency). Configurable in Preferences.
    var tickInterval: TimeInterval

    private(set) var isPlaying = false
    private(set) var distanceCovered: Double = 0
    private(set) var totalDistance: Double = 0

    private var polyline: [RouteCoordinate] = []
    private var cumulative: [Double] = []

    init(
        profile: MovementProfile = .driving,
        speed: PlaybackSpeed = .normal,
        loops: Bool = false,
        tickInterval: TimeInterval = 1
    ) {
        self.profile = profile
        self.speed = speed
        self.loops = loops
        self.tickInterval = tickInterval
    }

    /// Loads a new polyline and restarts playback.
    func load(polyline: [RouteCoordinate]) {
        self.polyline = polyline
        cumulative = GeoMath.cumulativeDistances(polyline)
        totalDistance = cumulative.last ?? 0
        distanceCovered = 0
        isPlaying = false
    }

    // MARK: - Derived values

    /// Current speed in m/s (profile × multiplier).
    var currentSpeedMetersPerSecond: Double {
        profile.speedMetersPerSecond * speed.multiplier
    }

    /// Progress from 0 to 1.
    var progress: Double {
        totalDistance > 0 ? min(distanceCovered / totalDistance, 1) : 0
    }

    /// Total trip duration at 1× (basis for the "Duration (1×)" card).
    var routeDuration1x: TimeInterval {
        profile.speedMetersPerSecond > 0 ? totalDistance / profile.speedMetersPerSecond : 0
    }

    /// Total duration at the current playback speed (the bar's total).
    var playbackDuration: TimeInterval {
        currentSpeedMetersPerSecond > 0 ? totalDistance / currentSpeedMetersPerSecond : 0
    }

    /// Elapsed time at the current playback speed.
    var playbackElapsed: TimeInterval {
        playbackDuration * progress
    }

    /// Current coordinate along the trip.
    var currentCoordinate: RouteCoordinate? {
        GeoMath.point(atDistance: distanceCovered, polyline: polyline, cumulative: cumulative)?.coordinate
    }

    /// Current heading (degrees, 0 = North).
    var currentHeading: Double {
        GeoMath.point(atDistance: distanceCovered, polyline: polyline, cumulative: cumulative)?.heading ?? 0
    }

    // MARK: - Controls

    func play() {
        guard totalDistance > 0 else { return }
        isPlaying = true
    }

    func pause() {
        isPlaying = false
    }

    func reset() {
        isPlaying = false
        distanceCovered = 0
    }

    /// Positions playback at a fraction of the trip (0–1).
    func seek(toProgress fraction: Double) {
        guard totalDistance > 0 else { return }
        distanceCovered = totalDistance * min(max(fraction, 0), 1)
    }

    /// Advances one interval. No-op when paused.
    func tick() {
        guard isPlaying else { return }
        distanceCovered += currentSpeedMetersPerSecond * tickInterval

        guard distanceCovered >= totalDistance else { return }
        if loops, totalDistance > 0 {
            distanceCovered = distanceCovered.truncatingRemainder(dividingBy: totalDistance)
        } else {
            distanceCovered = totalDistance
            isPlaying = false
        }
    }
}
