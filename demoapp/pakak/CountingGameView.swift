//
//  CountingGameView.swift
//  pakak
//

import SwiftUI

struct CountingGameView: View {
    private struct Round {
        let objects: [String]
        let target: Int
        let options: [Int]

        /// Two rounds count as the same question when the amount and the objects match.
        var key: String { "\(target)|\(Set(objects).sorted().joined())" }
    }

    @Environment(GameProgress.self) private var progress

    @State private var round = Round(objects: [], target: 0, options: [])
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var didLevelUp = false
    @State private var shakeWrong = false

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

    var body: some View {
        ZStack {
            KidBackdrop()

            ScrollView {
                VStack(spacing: 20) {
                    LevelBadge(
                        level: level,
                        answersInLevel: progress.answersInCurrentLevel(for: activityName)
                    )

                    Text("How many do you see?")
                        .font(.title.bold())
                        .foregroundStyle(KidTheme.headline)

                    objectGrid

                    Text("Tap the right number!")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    answerGrid
                }
                .padding()
            }

            if showCelebration {
                CelebrationOverlay(message: celebrationMessage, leveledUp: didLevelUp)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("Counting")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newRound() }
        .sensoryFeedback(.success, trigger: showCelebration)
        .sensoryFeedback(.error, trigger: shakeWrong)
    }

    private var objectGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(round.objects.indices, id: \.self) { index in
                Text(round.objects[index])
                    .font(.system(size: tileSide * 0.68))
                    .frame(width: tileSide, height: tileSide)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.6))
        )
        .modifier(ShakeEffect(shakes: shakeWrong ? 2 : 0))
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
        let picker = QuestionPicker(progress: progress, activity: activityName)
        let next = picker.fresh(make: makeRound, key: { $0.key })
        picker.note(next.key)
        round = next
        showCelebration = false
    }

    private func makeRound() -> Round {
        let target = Int.random(in: min(minCount, maxCount)...maxCount)
        let palette = Array(emojiPool.shuffled().prefix(objectKinds))
        let objects = (0..<target).compactMap { _ in palette.randomElement() }

        return Round(objects: objects, target: target, options: numberOptions(for: target))
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
        guard answer == round.target else {
            shakeWrong.toggle()
            return
        }

        didLevelUp = progress.recordCorrect(for: activityName)
        celebrationMessage = didLevelUp ? "Level \(level) unlocked!" : "Great counting!"
        withAnimation { showCelebration = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            newRound()
        }
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
