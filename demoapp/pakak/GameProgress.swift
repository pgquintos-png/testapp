//
//  GameProgress.swift
//  pakak
//

import SwiftUI

@Observable
final class GameProgress {
    /// One correct answer per level — so 100 correct answers completes a game.
    static let answersPerLevel = 1
    static let maxLevel = 100

    var totalStars: Int = 0

    /// Coupon codes keyed by activity name, generated once when the game is first completed.
    private var couponCodes: [String: String] = [:]

    private var levels: [String: Int] = [:]
    private var answersInLevel: [String: Int] = [:]
    /// Every question asked per activity, oldest first, so games can avoid repeating themselves.
    private var askedKeys: [String: [String]] = [:]

    private static let memoryLimit = 400

    /// Where the saved game lives. Injectable so a test can hand over a scratch suite instead of
    /// writing over the progress on the device.
    private let defaults: UserDefaults
    private static let storageKey = "pakak.progress"

    /// Everything worth keeping between launches. Versioned so a later format change can recognise
    /// an old save rather than misreading it.
    private struct Snapshot: Codable {
        static let currentVersion = 1

        var version = currentVersion
        var totalStars: Int
        var couponCodes: [String: String]
        var levels: [String: Int]
        var answersInLevel: [String: Int]
        var askedKeys: [String: [String]]
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    /// Progress is written after every change rather than on the way out, so a game survives the
    /// app being swiped away, crashing, or the battery running out between questions.
    private func save() {
        let snapshot = Snapshot(
            totalStars: totalStars,
            couponCodes: couponCodes,
            levels: levels,
            answersInLevel: answersInLevel,
            askedKeys: askedKeys
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    /// A missing or unreadable save is not worth complaining about — it just means a child who has
    /// not played yet, so the games open at level 1 as they always did.
    private func load() {
        guard let data = defaults.data(forKey: Self.storageKey),
              let saved = try? JSONDecoder().decode(Snapshot.self, from: data),
              saved.version == Snapshot.currentVersion
        else { return }

        totalStars = saved.totalStars
        couponCodes = saved.couponCodes
        levels = saved.levels
        answersInLevel = saved.answersInLevel
        askedKeys = saved.askedKeys
    }

    func level(for activity: String) -> Int {
        levels[activity] ?? 1
    }

    func answersInCurrentLevel(for activity: String) -> Int {
        answersInLevel[activity] ?? 0
    }

    func difficulty(for activity: String) -> Difficulty {
        Difficulty(level: level(for: activity))
    }

    /// True when the player has answered 100 questions correctly in this activity.
    func isComplete(for activity: String) -> Bool {
        level(for: activity) >= Self.maxLevel
    }

    /// Returns the persistent coupon code for a completed activity,
    /// generating and storing one on first call.
    func couponCode(for activity: String) -> String {
        if let existing = couponCodes[activity] { return existing }
        let code = Self.generateCode(for: activity)
        couponCodes[activity] = code
        save()
        return code
    }

    private static func generateCode(for activity: String) -> String {
        let seeds = ["STAR", "MOON", "SUN", "HEART", "GEMS", "CROWN"]
        let hash = activity.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        let word = seeds[hash % seeds.count]
        let digits = String(format: "%04d", (hash &* 1_337) % 9_000 + 1_000)
        return "PAKAK-\(word)-\(digits)"
    }

    /// Awards a star and reports whether this answer unlocked the next level.
    @discardableResult
    func recordCorrect(for activity: String) -> Bool {
        totalStars += 1

        let answered = answersInCurrentLevel(for: activity) + 1
        guard answered >= Self.answersPerLevel else {
            answersInLevel[activity] = answered
            save()
            return false
        }

        answersInLevel[activity] = 0
        let current = level(for: activity)
        guard current < Self.maxLevel else {
            save()
            return false
        }

        levels[activity] = current + 1
        save()
        return true
    }

    func noteAsked(_ key: String, in activity: String) {
        var keys = askedKeys[activity] ?? []
        keys.append(key)
        if keys.count > Self.memoryLimit {
            keys.removeFirst(keys.count - Self.memoryLimit)
        }
        askedKeys[activity] = keys
        save()
    }

    /// How many questions ago this one was asked. A question never asked returns `Int.max`.
    func questionsSince(_ key: String, in activity: String) -> Int {
        guard let keys = askedKeys[activity], let index = keys.lastIndex(of: key) else {
            return .max
        }
        return keys.count - index
    }
}

/// Hands out questions that the child has not just been asked.
struct QuestionPicker {
    let progress: GameProgress
    let activity: String

    /// Picks at random from whichever entries have gone longest without being used, so a pool is
    /// worked through completely — in a fresh order each time — before anything comes round again.
    func choose<T>(from pool: [T], key: (T) -> String) -> T? {
        guard !pool.isEmpty else { return nil }

        let aged = pool.map { (item: $0, age: progress.questionsSince(key($0), in: activity)) }
        guard let oldest = aged.map(\.age).max() else { return nil }
        return aged.filter { $0.age == oldest }.randomElement()?.item
    }

    /// Rerolls a randomly built question until it finds one that has not come up lately, and keeps
    /// the stalest draw rather than the last one. Without that, a game with only a handful of
    /// possible questions would run out of rerolls and hand back an immediate repeat.
    func fresh<T>(gap: Int = 25, attempts: Int = 30, make: () -> T, key: (T) -> String) -> T {
        var best = make()
        var bestAge = progress.questionsSince(key(best), in: activity)

        var tries = 1
        while bestAge <= gap, tries < attempts {
            let candidate = make()
            let age = progress.questionsSince(key(candidate), in: activity)
            if age > bestAge {
                best = candidate
                bestAge = age
            }
            tries += 1
        }

        return best
    }

    func note(_ key: String) {
        progress.noteAsked(key, in: activity)
    }
}

struct Activity: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let emoji: String
    let colorIndex: Int
}

let learningActivities: [Activity] = [
    Activity(title: "Counting", subtitle: "How many?", emoji: "🔢", colorIndex: 0),
    Activity(title: "Colors", subtitle: "Find the color!", emoji: "🎨", colorIndex: 1),
    Activity(title: "Alphabet", subtitle: "Learn your ABCs", emoji: "🔤", colorIndex: 2),
    Activity(title: "Shapes", subtitle: "Spot the shape!", emoji: "⭐", colorIndex: 3),
    Activity(title: "Brain Teaser", subtitle: "Puzzle time!", emoji: "🧩", colorIndex: 4),
    Activity(title: "Logic Puzzles", subtitle: "Look and think!", emoji: "🧠", colorIndex: 5),
    Activity(title: "Word Riddles", subtitle: "Tricky words!", emoji: "💬", colorIndex: 6),
    Activity(title: "Riddles", subtitle: "Guess who I am!", emoji: "🕵️", colorIndex: 7),
]
