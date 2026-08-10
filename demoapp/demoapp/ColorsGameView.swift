//
//  ColorsGameView.swift
//  demoapp
//

import SwiftUI

struct ColorChallenge: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let emoji: String
}

let colorChallenges: [ColorChallenge] = [
    ColorChallenge(name: "Red", color: .red, emoji: "🍎"),
    ColorChallenge(name: "Blue", color: .blue, emoji: "🐳"),
    ColorChallenge(name: "Green", color: .green, emoji: "🌿"),
    ColorChallenge(name: "Yellow", color: .yellow, emoji: "🌻"),
    ColorChallenge(name: "Orange", color: .orange, emoji: "🍊"),
    ColorChallenge(name: "Purple", color: .purple, emoji: "🍇"),
    ColorChallenge(name: "Pink", color: .pink, emoji: "🌸"),
]

struct ColorsGameView: View {
    @Environment(GameProgress.self) private var progress

    @State private var challenge = colorChallenges.randomElement()!
    @State private var options: [ColorChallenge] = []
    @State private var showCelebration = false
    @State private var wrongTap = false

    var body: some View {
        ZStack {
            KidTheme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Text("Find the color!")
                    .font(.title.bold())
                    .foregroundStyle(Color(red: 0.2, green: 0.3, blue: 0.5))

                VStack(spacing: 16) {
                    Text(challenge.emoji)
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

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(options) { option in
                        Button {
                            checkAnswer(option)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 28, height: 28)
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                                Text(option.name)
                                    .font(.title3.bold())
                            }
                            .foregroundStyle(.white)
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
            .padding()

            if showCelebration {
                CelebrationOverlay(message: "You got it!")
            }
        }
        .navigationTitle("Colors")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newRound() }
        .sensoryFeedback(.success, trigger: showCelebration)
        .sensoryFeedback(.error, trigger: wrongTap)
    }

    private func newRound() {
        challenge = colorChallenges.randomElement()!
        let wrong = colorChallenges.filter { $0.name != challenge.name }.shuffled()
        options = ([challenge] + wrong.prefix(3)).shuffled()
        showCelebration = false
    }

    private func checkAnswer(_ answer: ColorChallenge) {
        if answer.name == challenge.name {
            progress.earnStar()
            withAnimation { showCelebration = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                newRound()
            }
        } else {
            wrongTap.toggle()
        }
    }
}

#Preview {
    NavigationStack {
        ColorsGameView()
    }
    .environment(GameProgress())
}
