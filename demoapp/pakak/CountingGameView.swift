//
//  CountingGameView.swift
//  pakak
//

import SwiftUI

struct CountingGameView: View {
    /// Counting is the whole game to begin with. Sums join it once the child has proved they can
    /// count reliably, which is what reaching level 10 means here.
    private enum Question {
        case count, add, subtract
    }

    private struct Round {
        let question: Question
        /// The first panel: the whole group when counting or taking away, the first pile when adding.
        let objects: [String]
        /// The second pile, only used when adding.
        let extra: [String]
        /// How many objects at the end of `objects` are crossed out, only used when taking away.
        let takenAway: Int
        /// Later levels drop the pictures and leave the numbers to work with.
        let showsObjects: Bool
        let target: Int
        let options: [Int]

        var prompt: String {
            switch question {
            case .count: "How many do you see?"
            case .add: "How many altogether?"
            case .subtract: "How many are left?"
            }
        }

        /// The sum written out. Counting questions have nothing to write.
        var equation: String? {
            switch question {
            case .count: nil
            case .add: "\(objects.count) + \(extra.count) = ?"
            case .subtract: "\(objects.count) − \(takenAway) = ?"
            }
        }

        /// Shown when the answer was missed — the whole sum, not just the number.
        var reveal: String {
            switch question {
            case .count: "There were \(target)."
            case .add: "\(objects.count) + \(extra.count) = \(target)"
            case .subtract: "\(objects.count) − \(takenAway) = \(target)"
            }
        }

        /// Two rounds count as the same question when the sum and the objects match.
        var key: String {
            switch question {
            case .count: "count|\(target)|\(Set(objects).sorted().joined())"
            case .add: "add|\(objects.count)+\(extra.count)"
            case .subtract: "sub|\(objects.count)-\(takenAway)"
            }
        }
    }

    @Environment(GameProgress.self) private var progress

    @State private var round = Round(
        question: .count,
        objects: [],
        extra: [],
        takenAway: 0,
        showsObjects: true,
        target: 0,
        options: []
    )
    @State private var feedback = AnswerFeedback()

    private let activityName = "Counting"
    private let emojiPool = ["🍎", "🌟", "🐶", "🦋", "🌸", "🎈", "🐸", "🍪", "🍓", "🐝", "🐢", "🌺"]

    private var level: Int { progress.level(for: activityName) }
    private var difficulty: Difficulty { progress.difficulty(for: activityName) }

    private var maxCount: Int { difficulty.value(from: 5, to: 30, by: 80) }
    /// The smallest amount also climbs, otherwise a level 90 question could still be "how many is 2?".
    private var minCount: Int { difficulty.value(from: 1, to: 15, by: 90) }
    /// Higher levels mix different objects together so the child cannot count by pattern alone.
    private var objectKinds: Int {
        if difficulty.has(40) { return 3 }
        if difficulty.has(10) { return 2 }
        return 1
    }
    private var usesNearMisses: Bool { difficulty.has(8) }
    private var optionCount: Int { min(difficulty.optionCount, maxCount + 2) }
    private var columnCount: Int { maxCount > 15 ? 6 : (maxCount > 8 ? 5 : 4) }
    private var tileSide: CGFloat { maxCount > 15 ? 38 : (maxCount > 8 ? 44 : 56) }

    /// How often a question is a sum rather than a count. Nothing until level 10, then a growing
    /// share of them. This reads the level directly instead of going through `Difficulty.has`,
    /// which deliberately brings unlocks forward — adding and taking away should start exactly
    /// where a parent would expect it to, at level 10.
    private var arithmeticShare: Double {
        guard level >= 10 else { return 0 }
        return Double(difficulty.value(from: 0.35, to: 0.85, by: 70))
    }

    /// Once the sums are familiar the counters come away and only the numbers are left.
    private var showsCounters: Bool { !difficulty.has(60) }

    var body: some View {
        ZStack {
            KidBackdrop()

            ScrollView {
                VStack(spacing: 20) {
                    LevelBadge(
                        level: level,
                        answersInLevel: progress.answersInCurrentLevel(for: activityName)
                    )

                    Text(round.prompt)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(KidTheme.headline)

                    stage

                    Text("Tap the right number!")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    answerGrid
                }
                .padding()
            }

            if let banner = feedback.banner {
                FeedbackOverlay(banner: banner)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("Counting")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newRound() }
        .sensoryFeedback(.success, trigger: feedback.rightTap)
        .sensoryFeedback(.error, trigger: feedback.wrongTap)
    }

    /// The objects to work from, the sum written underneath, or both.
    private var stage: some View {
        VStack(spacing: 14) {
            if round.showsObjects {
                objectPanel(round.objects, crossedFrom: round.objects.count - round.takenAway)

                if round.question == .add {
                    Text("+")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(KidTheme.headline)
                    objectPanel(round.extra)
                }
            }

            if let equation = round.equation {
                Text(equation)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(KidTheme.headline)
                    // With the counters gone the sum is the whole question, so it gets the card
                    // the objects would have been sitting on.
                    .padding(round.showsObjects ? 0 : 32)
                    .frame(maxWidth: round.showsObjects ? nil : .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(round.showsObjects ? 0 : 0.6))
                    )
            }
        }
        .modifier(ShakeEffect(shakes: feedback.wrongTap ? 2 : 0))
    }

    /// `crossedFrom` marks where the objects being taken away start, so they can be shown fading
    /// out of the group rather than as a second pile the child has to hold in their head.
    private func objectPanel(_ objects: [String], crossedFrom: Int = .max) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(objects.indices, id: \.self) { index in
                let isTaken = index >= crossedFrom

                Text(objects[index])
                    .font(.system(size: tileSide * 0.68))
                    .frame(width: tileSide, height: tileSide)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    )
                    .opacity(isTaken ? 0.35 : 1)
                    .overlay {
                        if isTaken {
                            Image(systemName: "xmark")
                                .font(.system(size: tileSide * 0.5, weight: .heavy))
                                .foregroundStyle(KidTheme.cardColors[0])
                        }
                    }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.6))
        )
    }

    private var answerGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(round.options, id: \.self) { number in
                AnswerButton(
                    title: "\(number)",
                    color: KidTheme.cardColors[number % KidTheme.cardColors.count]
                ) {
                    checkAnswer(number)
                }
            }
        }
    }

    private func newRound() {
        feedback.clear()

        let picker = QuestionPicker(progress: progress, activity: activityName)
        let next = picker.fresh(make: makeRound, key: { $0.key })
        picker.note(next.key)
        round = next
    }

    private func makeRound() -> Round {
        guard Double.random(in: 0..<1) < arithmeticShare else { return countingRound() }
        return Bool.random() ? additionRound() : subtractionRound()
    }

    private func countingRound() -> Round {
        let target = Int.random(in: min(minCount, maxCount)...maxCount)
        let palette = Array(emojiPool.shuffled().prefix(objectKinds))
        let objects = (0..<target).compactMap { _ in palette.randomElement() }

        return Round(
            question: .count,
            objects: objects,
            extra: [],
            takenAway: 0,
            showsObjects: true,
            target: target,
            options: numberOptions(for: target)
        )
    }

    /// Two piles side by side. Each pile keeps to one kind of object so the child can see which
    /// pile is which without counting the same thing twice.
    private func additionRound() -> Round {
        let total = Int.random(in: sumRange)
        let first = Int.random(in: 1..<total)
        let palette = emojiPool.shuffled()

        return Round(
            question: .add,
            objects: Array(repeating: palette[0], count: first),
            extra: Array(repeating: palette[1], count: total - first),
            takenAway: 0,
            showsObjects: showsCounters,
            target: total,
            options: numberOptions(for: total)
        )
    }

    private func subtractionRound() -> Round {
        let total = Int.random(in: sumRange)
        let takenAway = Int.random(in: 1..<total)
        let emoji = emojiPool.randomElement() ?? "🍎"

        return Round(
            question: .subtract,
            objects: Array(repeating: emoji, count: total),
            extra: [],
            takenAway: takenAway,
            showsObjects: showsCounters,
            target: total - takenAway,
            options: numberOptions(for: total - takenAway)
        )
    }

    /// Sums need at least two objects to split, and grow with the same ceiling as counting.
    private var sumRange: ClosedRange<Int> {
        let top = max(2, maxCount)
        return min(max(2, minCount), top)...top
    }

    /// Once past level 8 the wrong answers crowd around the target, so the child has to count
    /// exactly. They are sampled from a wider band than needed, otherwise the answer would always
    /// be the middle number of the choices.
    private func numberOptions(for target: Int) -> [Int] {
        var candidates = Array(1...(maxCount + 2)).filter { $0 != target }
        if usesNearMisses {
            candidates.sort { abs($0 - target) < abs($1 - target) }
            candidates = Array(candidates.prefix(optionCount + 2)).shuffled()
        } else {
            candidates.shuffle()
        }

        return ([target] + candidates.prefix(optionCount - 1)).shuffled()
    }

    private func checkAnswer(_ answer: Int) {
        guard !feedback.isResolving else { return }

        guard answer == round.target else {
            feedback.wrong(round.reveal, then: newRound)
            return
        }

        let leveledUp = progress.recordCorrect(for: activityName)
        feedback.correct(
            leveledUp ? "Level \(level) unlocked!" : "Great counting!",
            leveledUp: leveledUp,
            then: newRound
        )
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 8 * sin(shakes * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

#Preview {
    NavigationStack {
        CountingGameView()
    }
    .environment(GameProgress())
}
