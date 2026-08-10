//
//  KidTheme.swift
//  demoapp
//

import SwiftUI

enum KidTheme {
    static let background = LinearGradient(
        colors: [Color(red: 0.95, green: 0.97, blue: 1.0), Color(red: 0.88, green: 0.94, blue: 1.0)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardColors: [Color] = [
        Color(red: 1.0, green: 0.55, blue: 0.45),
        Color(red: 0.45, green: 0.75, blue: 1.0),
        Color(red: 0.55, green: 0.85, blue: 0.55),
        Color(red: 0.95, green: 0.75, blue: 0.35),
        Color(red: 0.75, green: 0.55, blue: 0.95),
        Color(red: 0.35, green: 0.78, blue: 0.78),
        Color(red: 0.95, green: 0.55, blue: 0.72),
        Color(red: 0.6, green: 0.8, blue: 0.35),
    ]

    static let starGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let headline = Color(red: 0.2, green: 0.3, blue: 0.5)
    static let levelUp = Color(red: 0.55, green: 0.35, blue: 0.85)

    static func activityGradient(for index: Int) -> LinearGradient {
        let base = cardColors[index % cardColors.count]
        return LinearGradient(
            colors: [base, base.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func levelColor(for level: Int) -> Color {
        cardColors[(level - 1) % cardColors.count]
    }
}

struct KidCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct LevelBadge: View {
    let level: Int
    let answersInLevel: Int

    private var isMaxLevel: Bool { level >= GameProgress.maxLevel }

    var body: some View {
        HStack(spacing: 10) {
            Text("Level \(level)")
                .font(.headline.bold())

            if isMaxLevel {
                Image(systemName: "crown.fill")
                    .font(.subheadline)
            } else {
                HStack(spacing: 5) {
                    ForEach(0..<GameProgress.answersPerLevel, id: \.self) { index in
                        Circle()
                            .fill(index < answersInLevel ? Color.white : Color.white.opacity(0.35))
                            .frame(width: 9, height: 9)
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(KidTheme.levelColor(for: level))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: level)
    }
}

struct AnswerButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(color)
                        .shadow(color: color.opacity(0.4), radius: 6, y: 4)
                )
        }
        .buttonStyle(KidCardButtonStyle())
    }
}

struct CelebrationOverlay: View {
    let message: String
    var emoji: String = "🎉"
    var color: Color = Color.green.opacity(0.9)

    @State private var animate = false

    init(message: String, leveledUp: Bool) {
        self.init(
            message: message,
            emoji: leveledUp ? "🏆" : "🎉",
            color: leveledUp ? KidTheme.levelUp : Color.green.opacity(0.9)
        )
    }

    init(message: String, emoji: String = "🎉", color: Color = Color.green.opacity(0.9)) {
        self.message = message
        self.emoji = emoji
        self.color = color
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 64))
                .scaleEffect(animate ? 1.2 : 0.8)
            Text(message)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(color)
                .shadow(radius: 10)
        )
        .scaleEffect(animate ? 1.0 : 0.5)
        .opacity(animate ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                animate = true
            }
        }
    }
}
