//
//  LogicPuzzleGameView.swift
//  pakak
//

import SwiftUI

/// The drawing shown in a logic puzzle, either on the stage or inside an answer card.
enum LogicContent {
    case arrow(degrees: Double)
    case shape(ShapeType, tint: Color?, scale: CGFloat, outlined: Bool)
}

struct LogicOption: Identifiable {
    let id: Int
    let content: LogicContent
    let isCorrect: Bool
}

enum LogicStage {
    case single(LogicContent)
    case grid([[LogicContent?]])
}

struct LogicPuzzle {
    let prompt: String
    let stage: LogicStage?
    let options: [LogicOption]
    let hint: String
    let key: String
}

enum LogicPuzzleFactory {
    private enum Kind {
        case shadow, ranking, rotation, grid
    }

    static func random(level: Int, picker: QuestionPicker) -> LogicPuzzle {
        var kinds: [Kind] = [.shadow, .ranking, .rotation]
        if Difficulty(level: level).has(10) { kinds.append(.grid) }

        switch kinds.randomElement() ?? .shadow {
        case .shadow: return shadow(level: level, picker: picker)
        case .ranking: return ranking(level: level)
        case .rotation: return rotation(level: level)
        case .grid: return grid(level: level)
        }
    }

    /// Naming a shape is harder than comparing one, so these puzzles draw on shapes well before the
    /// shapes game introduces them. It also keeps the early levels from recycling three shapes.
    private static func shapePool(for level: Int) -> [ShapeType] {
        ShapeType.allCases.filter { $0.unlockLevel <= max(level, 18) }
    }

    private static let gridColors: [Color] = [.red, .blue, .green, .orange, .purple]

    /// Match a solid silhouette to the matching outline, ignoring colour.
    private static func shadow(level: Int, picker: QuestionPicker) -> LogicPuzzle {
        let pool = shapePool(for: level)
        let target = picker.choose(from: pool, key: { "shadow:\($0.rawValue)" }) ?? pool.first ?? .circle
        let wanted = min(Difficulty(level: level).optionCount, pool.count)
        let decoys = pool.filter { $0 != target }.shuffled()
        let chosen = ([target] + decoys.prefix(wanted - 1)).shuffled()

        return LogicPuzzle(
            prompt: "Which outline matches the shadow?",
            stage: .single(.shape(target, tint: KidTheme.headline, scale: 1, outlined: false)),
            options: chosen.enumerated().map { index, shape in
                LogicOption(
                    id: index,
                    content: .shape(shape, tint: KidTheme.headline, scale: 0.55, outlined: true),
                    isCorrect: shape == target
                )
            },
            hint: "Trace the edges with your finger and compare the corners.",
            key: "shadow:\(target.rawValue)"
        )
    }

    /// Order by size. Later levels add more items, closer sizes, and second place questions.
    private static func ranking(level: Int) -> LogicPuzzle {
        let difficulty = Difficulty(level: level)
        let count = difficulty.value(from: 4, to: 6, by: 70)

        // The gap keeps narrowing all the way to level 90 instead of settling by 60, so the sizes
        // stay a real challenge to compare even at the top of the game.
        let gap = difficulty.value(from: 0.18, to: 0.09, by: 90)

        let shape = shapePool(for: level).randomElement() ?? .circle
        let color = gridColors.randomElement() ?? .blue
        let scales = (0..<count).map { 0.6 + CGFloat($0) * gap }

        let asksBiggest = Bool.random()
        let asksSecond = difficulty.has(20) && Bool.random()
        let targetScale: CGFloat
        let prompt: String
        switch (asksBiggest, asksSecond) {
        case (true, false):
            targetScale = scales[count - 1]
            prompt = "Which one is the biggest?"
        case (false, false):
            targetScale = scales[0]
            prompt = "Which one is the smallest?"
        case (true, true):
            targetScale = scales[count - 2]
            prompt = "Which one is the second biggest?"
        case (false, true):
            targetScale = scales[1]
            prompt = "Which one is the second smallest?"
        }

        return LogicPuzzle(
            prompt: prompt,
            stage: nil,
            options: scales.shuffled().enumerated().map { index, scale in
                LogicOption(
                    id: index,
                    content: .shape(shape, tint: color, scale: scale, outlined: false),
                    isCorrect: scale == targetScale
                )
            },
            hint: asksSecond
                ? "Find the winner first, then look for the next one."
                : "Compare them two at a time.",
            key: "rank:\(shape.rawValue)|\(count)|\(prompt)"
        )
    }

    /// Mental rotation: work out where an arrow points after it turns.
    private static func rotation(level: Int) -> LogicPuzzle {
        let difficulty = Difficulty(level: level)
        // Quarter turns to begin with, then eighth turns, then twelfths, then twenty-fourths, which
        // makes the starting direction much harder to picture.
        let step: Double = difficulty.has(90) ? 15 : (difficulty.has(70) ? 30 : (difficulty.has(40) ? 45 : 90))
        let allAngles = stride(from: 0.0, to: 360.0, by: step).map { $0 }
        let start = allAngles.randomElement() ?? 0

        var turns: [(name: String, degrees: Double)] = [("to the right", 90)]
        if difficulty.has(6) { turns.append(("to the left", -90)) }
        if difficulty.has(20) { turns.append(("half way around", 180)) }
        let turn = turns.randomElement() ?? ("to the right", 90)

        let answer = normalized(start + turn.degrees)
        // The starting angle and the opposite turn are the tempting mistakes, so offer them first.
        var angles = [answer]
        let tempting = [start, normalized(start - turn.degrees), normalized(start + 180)]
        for angle in tempting + allAngles.shuffled() where angles.count < difficulty.optionCount {
            if !angles.contains(angle) { angles.append(angle) }
        }

        return LogicPuzzle(
            prompt: "This arrow turns \(turn.name). Where does it point then?",
            stage: .single(.arrow(degrees: start)),
            options: angles.shuffled().enumerated().map { index, angle in
                LogicOption(id: index, content: .arrow(degrees: angle), isCorrect: angle == answer)
            },
            hint: "Point your finger the same way, then turn your whole arm \(turn.name).",
            key: "turn:\(Int(start))|\(Int(turn.degrees))"
        )
    }

    /// Complete the grid: shapes change across the columns, colours down the rows.
    private static func grid(level: Int) -> LogicPuzzle {
        let difficulty = Difficulty(level: level)
        let dimension = difficulty.has(95) ? 5 : (difficulty.has(80) ? 4 : (difficulty.has(45) ? 3 : 2))
        let shapes = Array(shapePool(for: level).shuffled().prefix(dimension))
        let colorIndices = Array(gridColors.indices.shuffled().prefix(dimension))
        let variesSize = difficulty.has(20) && dimension == 2
        let scales: [CGFloat] = variesSize ? [0.7, 1.0] : Array(repeating: 1.0, count: dimension)

        guard shapes.count == dimension, colorIndices.count == dimension else {
            return ranking(level: level)
        }

        var rows: [[LogicContent?]] = []
        for row in 0..<dimension {
            rows.append((0..<dimension).map { column -> LogicContent? in
                let isMissing = row == dimension - 1 && column == dimension - 1
                return isMissing
                    ? nil
                    : .shape(
                        shapes[column],
                        tint: gridColors[colorIndices[row]],
                        scale: scales[row],
                        outlined: false
                    )
            })
        }

        let answerShape = shapes[dimension - 1]
        let answerColor = colorIndices[dimension - 1]
        let answerScale = scales[dimension - 1]

        var candidates: [(shape: ShapeType, colorIndex: Int, scale: CGFloat)] = []
        for shape in shapes {
            for colorIndex in colorIndices {
                for scale in Set(scales) {
                    candidates.append((shape, colorIndex, scale))
                }
            }
        }

        let wrong = candidates
            .filter { !($0.shape == answerShape && $0.colorIndex == answerColor && $0.scale == answerScale) }
            .shuffled()
            .prefix(difficulty.optionCount - 1)
        let all = ([(shape: answerShape, colorIndex: answerColor, scale: answerScale)] + wrong).shuffled()

        let cellScale: CGFloat = dimension >= 5 ? 0.42 : (dimension >= 4 ? 0.5 : 0.62)

        return LogicPuzzle(
            prompt: "Which piece finishes the picture?",
            stage: .grid(rows),
            options: all.enumerated().map { index, combo in
                LogicOption(
                    id: index,
                    content: .shape(
                        combo.shape,
                        tint: gridColors[combo.colorIndex],
                        scale: combo.scale * cellScale,
                        outlined: false
                    ),
                    isCorrect: combo.shape == answerShape
                        && combo.colorIndex == answerColor
                        && combo.scale == answerScale
                )
            },
            hint: "Look along the rows and then down the columns to spot what changes.",
            key: "grid:\(dimension)|\(shapes.map(\.rawValue).joined(separator: ","))|\(colorIndices.map(String.init).joined(separator: ","))"
        )
    }

    private static func normalized(_ degrees: Double) -> Double {
        let wrapped = degrees.truncatingRemainder(dividingBy: 360)
        return wrapped < 0 ? wrapped + 360 : wrapped
    }
}

struct LogicPuzzleGameView: View {
    @Environment(GameProgress.self) private var progress

    @State private var puzzle: LogicPuzzle?
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var didLevelUp = false
    @State private var wrongTap = false
    @State private var showHint = false

    private let activityName = "Logic Puzzles"

    private var level: Int { progress.level(for: activityName) }

    var body: some View {
        ZStack {
            KidBackdrop()

            ScrollView {
                VStack(spacing: 22) {
                    LevelBadge(
                        level: level,
                        answersInLevel: progress.answersInCurrentLevel(for: activityName)
                    )

                    if let puzzle {
                        Text(puzzle.prompt)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                            .foregroundStyle(KidTheme.headline)

                        if let stage = puzzle.stage {
                            stageView(stage)
                                .padding(24)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(.white.opacity(0.7))
                                        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                                )
                                .modifier(ShakeEffect(shakes: wrongTap ? 2 : 0))
                        }

                        optionGrid(for: puzzle)
                        hintSection(for: puzzle)
                    }
                }
                .padding()
            }

            if showCelebration {
                CelebrationOverlay(message: celebrationMessage, leveledUp: didLevelUp)
            }
        }
        .navigationTitle("Logic Puzzles")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newRound() }
        .sensoryFeedback(.success, trigger: showCelebration)
        .sensoryFeedback(.error, trigger: wrongTap)
    }

    @ViewBuilder
    private func stageView(_ stage: LogicStage) -> some View {
        switch stage {
        case .single(let content):
            drawing(content, baseSize: 96)
                .frame(height: 110)
        case .grid(let rows):
            let side: CGFloat = rows.count >= 5 ? 52 : (rows.count >= 4 ? 60 : 68)

            VStack(spacing: 8) {
                ForEach(rows.indices, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(rows[row].indices, id: \.self) { column in
                            cell(rows[row][column], side: side)
                        }
                    }
                }
            }
        }
    }

    private func cell(_ content: LogicContent?, side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(content == nil ? KidTheme.cardColors[4].opacity(0.2) : .white)

            if let content {
                drawing(content, baseSize: side * 0.62)
            } else {
                Text("?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(KidTheme.headline)
            }
        }
        .frame(width: side, height: side)
    }

    @ViewBuilder
    private func drawing(_ content: LogicContent, baseSize: CGFloat) -> some View {
        switch content {
        case .arrow(let degrees):
            Image(systemName: "arrow.up")
                .font(.system(size: baseSize, weight: .bold))
                .foregroundStyle(KidTheme.cardColors[1])
                .rotationEffect(.degrees(degrees))
        case .shape(let shape, let tint, let scale, let outlined):
            ShapeView(shape: shape, size: baseSize * scale, tint: tint, outlined: outlined)
        }
    }

    private func optionGrid(for puzzle: LogicPuzzle) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(puzzle.options) { option in
                Button {
                    check(option)
                } label: {
                    drawing(option.content, baseSize: 60)
                        .frame(maxWidth: .infinity, minHeight: 88)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
                        )
                }
                .buttonStyle(KidCardButtonStyle())
            }
        }
    }

    private func hintSection(for puzzle: LogicPuzzle) -> some View {
        VStack(spacing: 10) {
            if showHint {
                Text("💡 \(puzzle.hint)")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(KidTheme.starGold.opacity(0.18))
                    )
            } else {
                Button("Need a hint?") {
                    withAnimation { showHint = true }
                }
                .font(.headline)
                .tint(KidTheme.cardColors[5])
            }

            Button {
                newRound()
            } label: {
                Label("Skip this one", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
            }
            .tint(.secondary)
        }
    }

    private func newRound() {
        let picker = QuestionPicker(progress: progress, activity: activityName)
        let next = picker.fresh(
            gap: 14,
            make: { LogicPuzzleFactory.random(level: level, picker: picker) },
            key: { $0.key }
        )
        picker.note(next.key)
        puzzle = next
        showHint = false
        showCelebration = false
    }

    private func check(_ option: LogicOption) {
        guard option.isCorrect else {
            wrongTap.toggle()
            return
        }

        didLevelUp = progress.recordCorrect(for: activityName)
        celebrationMessage = didLevelUp ? "Level \(level) unlocked!" : "Smart thinking!"
        withAnimation { showCelebration = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            newRound()
        }
    }
}

#Preview {
    NavigationStack {
        LogicPuzzleGameView()
    }
    .environment(GameProgress())
}
