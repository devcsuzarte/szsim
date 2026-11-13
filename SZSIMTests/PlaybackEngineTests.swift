//
//  PlaybackEngineTests.swift
//  SZSIMTests
//

import Testing
@testable import SZSIM

@MainActor
struct PlaybackEngineTests {
    // Line from (0,0) to (0,1) ≈ 111,195 m.
    private func makeEngine(
        profile: MovementProfile = .driving,
        speed: PlaybackSpeed = .normal,
        loops: Bool = false
    ) -> PlaybackEngine {
        let engine = PlaybackEngine(profile: profile, speed: speed, loops: loops, tickInterval: 1)
        engine.load(polyline: [
            RouteCoordinate(latitude: 0, longitude: 0),
            RouteCoordinate(latitude: 0, longitude: 1),
        ])
        return engine
    }

    @Test func tickAdvancesByCurrentSpeed() {
        let engine = makeEngine() // carro 13,9 × 1×
        engine.play()
        engine.tick()
        #expect(abs(engine.distanceCovered - 13.9) < 0.001)
    }

    @Test func pauseStopsAdvancing() {
        let engine = makeEngine()
        engine.play()
        engine.tick()
        engine.pause()
        engine.tick()
        #expect(abs(engine.distanceCovered - 13.9) < 0.001)
    }

    @Test func speedChangeContinuesFromCurrentPosition() {
        let engine = makeEngine()
        engine.play()
        engine.tick()              // 13,9
        engine.speed = .double
        engine.tick()              // +27,8 => 41,7
        #expect(abs(engine.distanceCovered - 41.7) < 0.001)
    }

    @Test func resetReturnsToStart() {
        let engine = makeEngine()
        engine.play()
        engine.tick()
        engine.reset()
        #expect(engine.distanceCovered == 0)
        #expect(engine.isPlaying == false)
        #expect(engine.progress == 0)
    }

    @Test func stopsAtEndWhenNotLooping() {
        let engine = makeEngine(speed: .veryFast, loops: false)
        engine.play()
        for _ in 0..<2000 {
            engine.tick()
            if !engine.isPlaying { break }
        }
        #expect(engine.isPlaying == false)
        #expect(abs(engine.progress - 1) < 0.0001)
        #expect(abs(engine.distanceCovered - engine.totalDistance) < 0.001)
    }

    @Test func loopWrapsAtEnd() {
        let engine = makeEngine(speed: .veryFast, loops: true)
        engine.play()
        for _ in 0..<2000 {
            engine.tick()
        }
        #expect(engine.isPlaying == true)
        #expect(engine.distanceCovered < engine.totalDistance)
    }

    @Test func startPositionIsOrigin() {
        let engine = makeEngine()
        let coordinate = try? #require(engine.currentCoordinate)
        #expect(coordinate.map { approxEqual($0, RouteCoordinate(latitude: 0, longitude: 0)) } == true)
    }

    @Test func seekSetsProgressByFraction() {
        let engine = makeEngine()
        engine.seek(toProgress: 0.5)
        #expect(abs(engine.progress - 0.5) < 0.0001)
    }

    @Test func seekClampsOutOfRange() {
        let engine = makeEngine()
        engine.seek(toProgress: 2)
        #expect(engine.progress == 1)
        engine.seek(toProgress: -1)
        #expect(engine.progress == 0)
    }

    @Test func playbackDurationHalvesWhenSpeedDoubles() {
        let engine = makeEngine(speed: .normal)
        let baseDuration = engine.playbackDuration
        engine.speed = .double
        #expect(abs(engine.playbackDuration - baseDuration / 2) < 0.001)
    }
}
