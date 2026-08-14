//
//  Difficulty.swift
//  pakak
//

import Foundation
import SwiftUI

/// Turns a level between 1 and `GameProgress.maxLevel` into puzzle settings.
///
/// With a hundred levels the games cannot use hand written cases per level, so each setting is
/// described as a start value, an end value, and the level where it stops growing.
///
/// The shape of the climb matters as much as those end points. Spread evenly, a setting running
/// from 5 to 30 by level 80 moves about a third of a step per answer, so the first dozen questions
/// are indistinguishable from question one and the game feels stuck on its easiest setting long
/// after the child has outgrown it. Both of the knobs below are therefore front loaded: settings
/// cover roughly a quarter of their range in the first tenth of the climb, and a feature declared
/// at level 20 switches on at level 9. Nothing ever plateaus early — every setting still needs its
/// full peak to reach the hardest value, and the last unlocks still wait for the closing levels.
struct Difficulty {
    let level: Int

    /// Bends the climb upwards. Below 1 means early levels gain more than late ones; at 0.6 a
    /// setting is a quarter of the way to its hardest value after a tenth of the climb.
    private static let climbShape = 0.6

    /// Bends the unlock scale forwards. Above 1 means a feature arrives before the level it is
    /// declared at; at 1.5 `has(10)` fires at level 4, `has(50)` at 35, `has(90)` still at 85.
    private static let unlockShape = 1.5

    /// How far along the way to `peak` this level sits, from 0 at level 1 to 1 at `peak`.
    ///
    /// Rises fastest at the start and keeps rising, gently, right up to the peak.
    func ramp(by peak: Int) -> Double {
        guard peak > 1 else { return 1 }
        let evenly = min(1, max(0, Double(level - 1) / Double(peak - 1)))
        return pow(evenly, Self.climbShape)
    }

    func value(from start: Int, to end: Int, by peak: Int) -> Int {
        start + Int((Double(end - start) * ramp(by: peak)).rounded())
    }

    func value(from start: CGFloat, to end: CGFloat, by peak: Int) -> CGFloat {
        start + (end - start) * CGFloat(ramp(by: peak))
    }

    /// True once the level has reached `unlock`, used to switch content on.
    ///
    /// `unlock` places the feature on the same 1...100 scale as the levels, but it is a position in
    /// the run rather than a literal level: the switch is thrown early, and the earlier the feature
    /// sits the sooner it lands. Otherwise a whole quarter of a game would be one unchanging kind
    /// of question, since almost every game keeps its second question type behind `has(10)`.
    func has(_ unlock: Int) -> Bool { level >= Self.unlockLevel(unlock) }

    /// The level at which `has(unlock)` starts returning true. Ordering is preserved, so features
    /// still arrive in the order their unlocks are numbered.
    static func unlockLevel(_ unlock: Int) -> Int {
        let span = Double(GameProgress.maxLevel - 1)
        guard span > 0 else { return 1 }
        let placed = min(1, max(0, Double(unlock - 1) / span))
        return 1 + Int((pow(placed, unlockShape) * span).rounded())
    }

    /// The number of answer choices, which grows as the child gets further in. Reaching nine by
    /// level 45 rather than 75 keeps the pressure on through the middle of the game; the games cap
    /// this against their own pools, so nine only appears where there is material for it.
    var optionCount: Int { value(from: 4, to: 9, by: 45) }
}
