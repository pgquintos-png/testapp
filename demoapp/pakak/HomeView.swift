//
//  HomeView.swift
//  pakak
//

import SwiftUI

struct HomeView: View {
    @Environment(GameProgress.self) private var progress
    @State private var selectedActivity: Activity?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                KidBackdrop()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        activityGrid
                    }
                    .padding()
                }
            }
            .navigationDestination(item: $selectedActivity) { activity in
                destination(for: activity)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("🌈")
                .font(.system(size: 56))

            Text("Fun Learning!")
                .font(.largeTitle.bold())
                .foregroundStyle(KidTheme.headline)

            Text("Pick an activity to play")
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(0..<min(progress.totalStars, 10), id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundStyle(KidTheme.starGold)
                }
                if progress.totalStars > 0 {
                    Text("\(progress.totalStars) stars!")
                        .font(.headline)
                        .foregroundStyle(KidTheme.starGold)
                }
            }
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private var activityGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(learningActivities) { activity in
                Button {
                    selectedActivity = activity
                } label: {
                    ActivityCard(activity: activity, level: progress.level(for: activity.title))
                }
                .buttonStyle(KidCardButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func destination(for activity: Activity) -> some View {
        switch activity.title {
        case "Counting":
            CountingGameView()
        case "Colors":
            ColorsGameView()
        case "Alphabet":
            AlphabetGameView()
        case "Shapes":
            ShapesGameView()
        case "Brain Teaser":
            BrainTeaserGameView()
        case "Logic Puzzles":
            LogicPuzzleGameView()
        case "Word Riddles":
            WordRiddleGameView()
        case "Riddles":
            RiddleGameView()
        default:
            Text("Coming soon!")
        }
    }
}

struct ActivityCard: View {
    let activity: Activity
    let level: Int

    var body: some View {
        VStack(spacing: 10) {
            Text(activity.emoji)
                .font(.system(size: 44))

            Text(activity.title)
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(activity.subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))

            HStack(spacing: 4) {
                if level >= GameProgress.maxLevel {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                }
                Text("Level \(level)")
                    .font(.caption.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(.black.opacity(0.18)))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(KidTheme.activityGradient(for: activity.colorIndex))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        )
    }
}

#Preview {
    HomeView()
        .environment(GameProgress())
}
