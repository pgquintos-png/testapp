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
    /// Warm rather than alarming: a wrong answer is a moment to learn from, not a failure.
    static let tryAgain = Color(red: 0.98, green: 0.6, blue: 0.24)

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

/// The prize for finishing all 100 levels of a game: a gift voucher the child fills in themselves.
///
/// Sits at the top of a finished game and stays there. Until it is filled in it asks who can claim
/// it and what it is for; after that it shows the finished voucher, which can be shared or redone.
struct VoucherCard: View {
    let activity: String

    @Environment(GameProgress.self) private var progress

    @State private var editing = false

    var body: some View {
        Group {
            if let voucher = progress.voucher(for: activity), !editing {
                VoucherTicket(voucher: voucher) { editing = true }
            } else {
                VoucherForm(
                    activity: activity,
                    existing: progress.voucher(for: activity)
                ) { claimant, reward in
                    progress.issueVoucher(for: activity, claimant: claimant, reward: reward)
                    editing = false
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: editing)
    }
}

private struct VoucherForm: View {
    let activity: String
    let existing: Voucher?
    let onCreate: (String, String) -> Void

    private static let custom = "Something else"

    @State private var claimant = ""
    @State private var choice: String?
    @State private var customReward = ""

    private var reward: String {
        let picked = choice == Self.custom ? customReward : (choice ?? "")
        return picked.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var name: String { claimant.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canCreate: Bool { !name.isEmpty && !reward.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 6) {
                Text("🎟️")
                    .font(.system(size: 40))
                Text("\(activity) complete!")
                    .font(.title3.bold())
                Text("Make your gift voucher")
                    .font(.subheadline)
                    .opacity(0.9)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)

            Text("Claimable by")
                .font(.headline)
                .foregroundStyle(.white)

            TextField("Your name", text: $claimant)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                .foregroundStyle(KidTheme.headline)

            Text("This voucher is for")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Voucher.rewards + [Self.custom], id: \.self) { option in
                    Button {
                        choice = option
                    } label: {
                        Text(option)
                            .font(.subheadline.bold())
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.horizontal, 6)
                            .foregroundStyle(choice == option ? .white : KidTheme.headline)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(choice == option ? KidTheme.headline : .white)
                            )
                    }
                    .buttonStyle(KidCardButtonStyle())
                }
            }

            if choice == Self.custom {
                TextField("What can they claim?", text: $customReward)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                    .foregroundStyle(KidTheme.headline)
            }

            Button {
                onCreate(name, reward)
            } label: {
                Text(existing == nil ? "Make my voucher" : "Update voucher")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(KidTheme.headline.opacity(canCreate ? 1 : 0.4)))
            }
            .buttonStyle(KidCardButtonStyle())
            .disabled(!canCreate)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [KidTheme.levelUp, KidTheme.starGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .onAppear {
            guard let existing else { return }
            claimant = existing.claimant
            if Voucher.rewards.contains(existing.reward) {
                choice = existing.reward
            } else {
                choice = Self.custom
                customReward = existing.reward
            }
        }
    }
}

private struct VoucherTicket: View {
    let voucher: Voucher
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("OFFICIAL GIFT VOUCHER")
                    .font(.title3.weight(.heavy))
                    .tracking(1.5)
                Text("🎟️")
                    .font(.system(size: 32))
            }

            Divider().overlay(KidTheme.headline.opacity(0.4))

            VStack(spacing: 8) {
                row("Claimable by", voucher.claimant)
                row("Voucher ID", voucher.id)
            }

            dashed

            VStack(spacing: 6) {
                Text("THIS VOUCHER ENTITLES \(voucher.claimant.uppercased()) TO:")
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                Text(voucher.reward)
                    .font(.title2.bold())
                    .foregroundStyle(KidTheme.levelUp)
                    .multilineTextAlignment(.center)
            }

            dashed

            VStack(spacing: 8) {
                row("Issued by", Voucher.issuer)
                row("Date issued", voucher.issuedText)
                row("Expiration", Voucher.expiration)
            }

            Divider().overlay(KidTheme.headline.opacity(0.4))

            Text("Terms: Present this voucher to the issuer to redeem.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .opacity(0.8)

            HStack(spacing: 12) {
                ShareLink(item: voucher.text) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
            }
            .font(.subheadline.bold())
            .buttonStyle(.bordered)
            .tint(KidTheme.levelUp)
        }
        .foregroundStyle(KidTheme.headline)
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [KidTheme.levelUp, KidTheme.starGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
        )
    }

    private var dashed: some View {
        Rectangle()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            .frame(height: 1)
            .opacity(0.4)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label.uppercased())
                .font(.caption.bold())
                .opacity(0.7)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .multilineTextAlignment(.trailing)
        }
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

/// The pause between answering and the next question.
///
/// Games hand their result here instead of tracking overlays and timers themselves: this puts up
/// the right card, swallows taps while it is showing, and calls back when it is time to move on.
/// A wrong answer is treated the same way as a right one — it says what the answer was and then
/// the game moves along, so a child is never left tapping at a question they cannot solve.
@Observable
final class AnswerFeedback {
    struct Banner: Equatable {
        let message: String
        let emoji: String
        let color: Color
        let celebrates: Bool
    }

    private(set) var banner: Banner?
    /// Flipped on every wrong answer to drive the shake and the error haptic.
    private(set) var wrongTap = false
    /// Flipped on every right answer to drive the success haptic.
    private(set) var rightTap = false

    /// True while a card is up. Games check this before scoring so a second tap cannot answer a
    /// question that is already on its way out, or land on the one replacing it.
    var isResolving: Bool { banner != nil }

    private static let correctPause = 1.5
    /// Longer than the correct pause, because there is an answer to read before it disappears.
    private static let wrongPause = 2.2

    private static let encouragements = ["Not quite!", "Almost!", "Good try!", "So close!"]

    func correct(_ message: String, leveledUp: Bool, then advance: @escaping () -> Void) {
        guard !isResolving else { return }
        rightTap.toggle()
        show(
            Banner(
                message: message,
                emoji: leveledUp ? "🏆" : "🎉",
                color: leveledUp ? KidTheme.levelUp : Color.green.opacity(0.9),
                celebrates: true
            ),
            for: Self.correctPause,
            then: advance
        )
    }

    /// `reveal` names the answer that was being looked for, and gets an encouraging line above it.
    func wrong(_ reveal: String, then advance: @escaping () -> Void) {
        guard !isResolving else { return }
        wrongTap.toggle()
        show(
            Banner(
                message: "\(Self.encouragements.randomElement() ?? "Not quite!")\n\(reveal)",
                emoji: "💡",
                color: KidTheme.tryAgain,
                celebrates: false
            ),
            for: Self.wrongPause,
            then: advance
        )
    }

    /// Called by each game as it lines up the next question.
    func clear() { banner = nil }

    private func show(_ banner: Banner, for pause: Double, then advance: @escaping () -> Void) {
        withAnimation { self.banner = banner }
        DispatchQueue.main.asyncAfter(deadline: .now() + pause, execute: advance)
    }
}

struct FeedbackOverlay: View {
    let banner: AnswerFeedback.Banner

    @State private var animate = false

    var body: some View {
        ZStack {
            if animate && banner.celebrates {
                ConfettiBurst()
            }

            VStack(spacing: 12) {
                Text(banner.emoji)
                    .font(.system(size: 64))
                    .scaleEffect(animate ? 1.2 : 0.8)
                Text(banner.message)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(banner.color)
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
