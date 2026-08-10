//
//  ColorsGameView.swift
//  demoapp
//

import SwiftUI
import UIKit

struct ColorChallenge: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    /// Several objects per colour, so the same colour can be asked in different ways.
    let examples: [String]
    let unlockLevel: Int
}

let colorChallenges: [ColorChallenge] = [
    ColorChallenge(name: "Red", color: .red, examples: ["🍎", "🍓", "🌹", "🚒"], unlockLevel: 1),
    ColorChallenge(name: "Blue", color: .blue, examples: ["🐳", "🫐", "💙"], unlockLevel: 1),
    ColorChallenge(name: "Green", color: .green, examples: ["🌿", "🥦", "🐢"], unlockLevel: 1),
    ColorChallenge(name: "Yellow", color: .yellow, examples: ["🌻", "🍋", "⭐"], unlockLevel: 1),
    ColorChallenge(name: "Orange", color: .orange, examples: ["🍊", "🥕", "🦊"], unlockLevel: 8),
    ColorChallenge(name: "Purple", color: .purple, examples: ["🍇", "🟣", "🔮"], unlockLevel: 8),
    ColorChallenge(name: "Pink", color: .pink, examples: ["🌸", "🐷", "🎀"], unlockLevel: 8),
    ColorChallenge(
        name: "Brown",
        color: Color(red: 0.55, green: 0.35, blue: 0.2),
        examples: ["🐻", "🍫", "🥔"],
        unlockLevel: 18
    ),
    ColorChallenge(name: "Gray", color: Color(white: 0.6), examples: ["🐘", "🪨", "🐺"], unlockLevel: 18),
    ColorChallenge(name: "Black", color: Color(white: 0.15), examples: ["🐈‍⬛", "🖤", "🎩"], unlockLevel: 28),
    ColorChallenge(name: "White", color: Color(white: 0.97), examples: ["☁️", "🥚", "🦢"], unlockLevel: 28),
    ColorChallenge(name: "Teal", color: .teal, examples: ["🦚"], unlockLevel: 38),
    ColorChallenge(
        name: "Gold",
        color: Color(red: 0.85, green: 0.68, blue: 0.2),
        examples: ["🏆", "🥇"],
        unlockLevel: 38
    ),
    ColorChallenge(name: "Silver", color: Color(white: 0.78), examples: ["🥈"], unlockLevel: 48),
    ColorChallenge(
        name: "Navy",
        color: Color(red: 0.1, green: 0.16, blue: 0.42),
        examples: ["👖"],
        unlockLevel: 48
    ),
    ColorChallenge(
        name: "Lime",
        color: Color(red: 0.65, green: 0.9, blue: 0.25),
        examples: ["🍏", "🥝"],
        unlockLevel: 48
    ),
    ColorChallenge(
        name: "Peach",
        color: Color(red: 1.0, green: 0.8, blue: 0.62),
        examples: ["🍑"],
        unlockLevel: 58
    ),
    ColorChallenge(
        name: "Beige",
        color: Color(red: 0.89, green: 0.84, blue: 0.7),
        examples: ["🍞", "🥯"],
        unlockLevel: 58
    ),
]

struct ColorsGameView: View {
    private struct Round {
        let challenge: ColorChallenge
        let example: String
        let options: [ColorChallenge]

        var key: String { "\(challenge.name)|\(example)" }
    }

    @Environment(GameProgress.self) private var progress

    @State private var round: Round?
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var didLevelUp = false
    @State private var wrongTap = false

    private let activityName = "Colors"

    private var level: Int { progress.level(for: activityName) }
    private var difficulty: Difficulty { progress.difficulty(for: activityName) }
    private var usesSimilarShades: Bool { difficulty.has(16) }
    private var availableChallenges: [ColorChallenge] {
        colorChallenges.filter { $0.unlockLevel <= level }
    }
    private var optionCount: Int { min(difficulty.optionCount, availableChallenges.count) }

    var body: some View {
        ZStack {
            KidTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    LevelBadge(
                        level: level,
                        answersInLevel: progress.answersInCurrentLevel(for: activityName)
                    )

                    Text("Find the color!")
                        .font(.title.bold())
                        .foregroundStyle(KidTheme.headline)

                    if let round {
                        promptCard(for: round)
                        optionGrid(for: round)
                    }
                }
                .padding()
            }

            if showCelebration {
                CelebrationOverlay(message: celebrationMessage, leveledUp: didLevelUp)
            }
        }
        .navigationTitle("Colors")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newRound() }
        .sensoryFeedback(.success, trigger: showCelebration)
        .sensoryFeedback(.error, trigger: wrongTap)
    }

    private func promptCard(for round: Round) -> some View {
        VStack(spacing: 16) {
            Text(round.example)
                .font(.system(size: 80))

            Text("What color is this?")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.7))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        )
        .modifier(ShakeEffect(shakes: wrongTap ? 2 : 0))
    }

    private func optionGrid(for round: Round) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(round.options) { option in
                Button {
                    check(option, in: round)
                } label: {
                    let ink = Self.readableInk(on: option.color)
                    HStack {
                        Circle()
                            .fill(option.color)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(ink, lineWidth: 2))
                        Text(option.name)
                            .font(.title3.bold())
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(option.color.opacity(0.85))
                            .shadow(color: option.color.opacity(0.4), radius: 5, y: 3)
                    )
                }
                .buttonStyle(KidCardButtonStyle())
            }
        }
    }

    private func newRound() {
        let picker = QuestionPicker(progress: progress, activity: activityName)
        let questions = availableChallenges.flatMap { challenge in
            challenge.examples.map { (challenge: challenge, example: $0) }
        }

        guard let picked = picker.choose(from: questions, key: { "\($0.challenge.name)|\($0.example)" }) else {
            return
        }

        var decoys = availableChallenges.filter { $0.name != picked.challenge.name }
        if usesSimilarShades {
            // Offer similar shades so the choice takes real looking, not guessing. Sampling from a
            // slightly wider band of near matches keeps the same colour from repeating choices.
            decoys.sort {
                Self.distance($0.color, picked.challenge.color) < Self.distance($1.color, picked.challenge.color)
            }
            decoys = Array(decoys.prefix(optionCount + 1)).shuffled()
        } else {
            decoys.shuffle()
        }

        let next = Round(
            challenge: picked.challenge,
            example: picked.example,
            options: ([picked.challenge] + decoys.prefix(optionCount - 1)).shuffled()
        )
        picker.note(next.key)
        round = next
        showCelebration = false
    }

    private func check(_ answer: ColorChallenge, in round: Round) {
        guard answer.name == round.challenge.name else {
            wrongTap.toggle()
            return
        }

        didLevelUp = progress.recordCorrect(for: activityName)
        celebrationMessage = didLevelUp ? "Level \(level) unlocked!" : "You got it!"
        withAnimation { showCelebration = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            newRound()
        }
    }

    /// Pale swatches like White and Gold need dark text to stay legible.
    private static func readableInk(on background: Color) -> Color {
        let parts = components(of: background)
        let brightness = 0.299 * parts.red + 0.587 * parts.green + 0.114 * parts.blue
        return brightness > 0.65 ? KidTheme.headline : .white
    }

    private static func distance(_ first: Color, _ second: Color) -> CGFloat {
        let lhs = components(of: first)
        let rhs = components(of: second)
        return pow(lhs.red - rhs.red, 2) + pow(lhs.green - rhs.green, 2) + pow(lhs.blue - rhs.blue, 2)
    }

    private static func components(of color: Color) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue)
    }
}

#Preview {
    NavigationStack {
        ColorsGameView()
    }
    .environment(GameProgress())
}
