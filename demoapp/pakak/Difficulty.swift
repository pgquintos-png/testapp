//
//  Difficulty.swift
//  pakak
//

import SwiftUI

/// Turns a level between 1 and `GameProgress.maxLevel` into puzzle settings.
///
/// With a hundred levels the games cannot use hand written cases per level, so each setting is
/// described as a start value, an end value, and the level where it stops growing.
struct Difficulty {
    let level: Int

    /// 0 at level 1, climbing to 1 by `peak` and staying there.
    func ramp(by peak: Int) -> Double {
        guard peak > 1 else { return 1 }
        return min(1, max(0, Double(level - 1) / Double(peak - 1)))
    }

    func value(from start: Int, to end: Int, by peak: Int) -> Int {
        start + Int((Double(end - start) * ramp(by: peak)).rounded())
    }

    func value(from start: CGFloat, to end: CGFloat, by peak: Int) -> CGFloat {
        start + (end - start) * CGFloat(ramp(by: peak))
    }

    /// True once the level has reached `unlock`, used to switch content on.
    func has(_ unlock: Int) -> Bool { level >= unlock }

    /// The number of answer choices, which grows as the child gets further in. Six steps instead
    /// of three keep the choice count climbing across the whole 100 levels rather than sitting flat
    /// at 8 for the entire second half of the game.
    var optionCount: Int {
        switch level {
        case ..<6: 4
        case ..<15: 5
        case ..<30: 6
        case ..<50: 7
        case ..<75: 8
        default: 9
        }
    }
}
