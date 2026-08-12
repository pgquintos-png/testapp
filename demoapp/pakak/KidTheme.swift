//
//  KidTheme.swift
//  pakak
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

/// The gradient every screen sits on, plus a handful of soft blurred shapes that drift gently in
/// place. Replaces a flat `KidTheme.background` fill with something livelier for kids without
/// competing with the foreground content.
struct KidBackdrop: View {
    private struct Blob {
        let color: Color
        let size: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    private static let blobs: [Blob] = [
        Blob(color: KidTheme.cardColors[1], size: 220, x: -0.32, y: -0.16),
        Blob(color: KidTheme.cardColors[3], size: 170, x: 0.34, y: 0.06),
        Blob(color: KidTheme.cardColors[6], size: 190, x: -0.28, y: 0.42),
        Blob(color: KidTheme.cardColors[5], size: 150, x: 0.3, y: 0.62),
    ]

    @State private var drift = false

    var body: some View {
        ZStack {
            KidTheme.background

            GeometryReader { proxy in
                ForEach(Self.blobs.indices, id: \.self) { index in
                    let blob = Self.blobs[index]
                    Circle()
                        .fill(blob.color.opacity(0.16))
                        .frame(width: blob.size, height: blob.size)
                        .blur(radius: 30)
                        .position(
                            x: proxy.size.width * (0.5 + blob.x),
                            y: proxy.size.height * (0.5 + blob.y) + (drift ? -12 : 12)
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
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
        ZStack {
            if animate {
                ConfettiBurst()
            }

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
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                animate = true
            }
        }
    }
}

/// A short burst of colourful pieces flung out from the centre, layered behind the celebration
/// card. Purely decorative, so it fades away rather than waiting to be dismissed.
private struct ConfettiBurst: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let color: Color
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
    }

    @State private var pieces: [Piece] = []
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .offset(
                        x: animate ? CGFloat(cos(piece.angle * .pi / 180)) * piece.distance : 0,
                        y: animate ? CGFloat(sin(piece.angle * .pi / 180)) * piece.distance + 30 : 0
                    )
                    .rotationEffect(.degrees(animate ? Double.random(in: 180...540) : 0))
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            pieces = (0..<18).map { index in
                Piece(
                    color: KidTheme.cardColors.randomElement() ?? KidTheme.starGold,
                    angle: Double(index) / 18 * 360 + Double.random(in: -10...10),
                    distance: CGFloat.random(in: 90...160),
                    size: CGFloat.random(in: 7...11)
                )
            }
            withAnimation(.easeOut(duration: 0.9)) {
                animate = true
            }
        }
    }
}
