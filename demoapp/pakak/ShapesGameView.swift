//
//  ShapesGameView.swift
//  pakak
//

import SwiftUI

enum ShapeType: String, CaseIterable, Identifiable {
    case circle = "Circle"
    case square = "Square"
    case triangle = "Triangle"
    case star = "Star"
    case heart = "Heart"
    case oval = "Oval"
    case diamond = "Diamond"
    case pentagon = "Pentagon"
    case hexagon = "Hexagon"
    case heptagon = "Heptagon"
    case octagon = "Octagon"

    var id: String { rawValue }

    var unlockLevel: Int {
        switch self {
        case .circle, .square, .triangle: 1
        case .star, .heart: 8
        case .oval, .diamond: 18
        case .pentagon, .hexagon: 30
        case .heptagon, .octagon: 45
        }
    }

    var color: Color {
        switch self {
        case .circle: .blue
        case .square: .orange
        case .triangle: .green
        case .star: .yellow
        case .heart: .pink
        case .oval: .purple
        case .diamond: .teal
        case .pentagon: .indigo
        case .hexagon: .red
        case .heptagon: .brown
        case .octagon: .cyan
        }
    }

    /// A tilted square reads as a diamond, so those two are always shown upright.
    var allowsRotation: Bool {
        self != .square && self != .diamond
    }
}

struct ShapeView: View {
    let shape: ShapeType
    var size: CGFloat = 100
    /// Overrides the shape's own colour, which the logic puzzles need for silhouettes and grids.
    var tint: Color?
    var outlined: Bool = false

    private var paint: Color { tint ?? shape.color }

    var body: some View {
        switch shape {
        case .circle:
            drawn(Circle())
        case .square:
            drawn(RoundedRectangle(cornerRadius: 8))
        case .triangle:
            drawn(Triangle())
        case .oval:
            drawn(Ellipse(), height: size * 0.62)
        case .diamond:
            drawn(Diamond())
        case .pentagon:
            drawn(RegularPolygon(sides: 5))
        case .hexagon:
            drawn(RegularPolygon(sides: 6))
        case .heptagon:
            drawn(RegularPolygon(sides: 7))
        case .octagon:
            drawn(RegularPolygon(sides: 8))
        case .star:
            symbol("star")
        case .heart:
            symbol("heart")
        }
    }

    private func drawn<S: Shape>(_ outline: S, height: CGFloat? = nil) -> some View {
        Group {
            if outlined {
                outline.stroke(paint, lineWidth: max(3, size * 0.07))
            } else {
                outline.fill(paint)
            }
        }
        .frame(width: size, height: height ?? size)
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: outlined ? name : "\(name).fill")
            .font(.system(size: size * 0.9))
            .foregroundStyle(paint)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.width * 0.16
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct RegularPolygon: Shape {
    let sides: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()

        for index in 0..<sides {
            let angle = (Double(index) / Double(sides)) * 2 * .pi - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

struct ShapesGameView: View {
    @Environment(GameProgress.self) private var progress

    @State private var targetShape = ShapeType.circle
    @State private var options: [ShapeType] = []
    @State private var rotation: Double = 0
    @State private var feedback = AnswerFeedback()

    private let activityName = "Shapes"

    private var level: Int { progress.level(for: activityName) }
    private var difficulty: Difficulty { progress.difficulty(for: activityName) }
    private var availableShapes: [ShapeType] {
        ShapeType.allCases.filter { $0.unlockLevel <= level }
    }
    private var optionCount: Int { min(difficulty.optionCount, availableShapes.count) }
    /// Shapes start tilting past level 40, and the tilt grows the further the child gets.
    private var maxTilt: Int { difficulty.value(from: 12, to: 45, by: 90) }

    var body: some View {
        ZStack {
            KidBackdrop()

            ScrollView {
                VStack(spacing: 24) {
                    LevelBadge(
                        level: level,
                        answersInLevel: progress.answersInCurrentLevel(for: activityName)
                    )

                    Text("What shape is this?")
                        .font(.title.bold())
                        .foregroundStyle(KidTheme.headline)

                    ShapeView(shape: targetShape, size: 120)
                        .rotationEffect(.degrees(rotation))
                        .frame(width: 160, height: 160)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.white.opacity(0.7))
                                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                        )
                        .modifier(ShakeEffect(shakes: feedback.wrongTap ? 2 : 0))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(options) { shape in
                            AnswerButton(title: shape.rawValue, color: shape.color) {
                                checkAnswer(shape)
                            }
                        }
                    }
                }
                .padding()
            }

            if let banner = feedback.banner {
                FeedbackOverlay(banner: banner)
            }
        }
        .navigationTitle("Shapes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newRound() }
        .sensoryFeedback(.success, trigger: feedback.rightTap)
        .sensoryFeedback(.error, trigger: feedback.wrongTap)
    }

    private func newRound() {
        feedback.clear()

        let picker = QuestionPicker(progress: progress, activity: activityName)
        let pool = availableShapes
        // Cycling through every unlocked shape before repeating keeps the questions from clumping.
        targetShape = picker.choose(from: pool, key: { $0.rawValue }) ?? .circle
        picker.note(targetShape.rawValue)

        let decoys = pool.filter { $0 != targetShape }.shuffled()
        options = ([targetShape] + decoys.prefix(optionCount - 1)).shuffled()

        let tilts = difficulty.has(40) && targetShape.allowsRotation
        rotation = tilts ? Double(Int.random(in: 12...maxTilt) * (Bool.random() ? 1 : -1)) : 0
    }

    private func checkAnswer(_ answer: ShapeType) {
        guard !feedback.isResolving else { return }

        guard answer == targetShape else {
            feedback.wrong("That was a \(targetShape.rawValue).", then: newRound)
            return
        }

        let leveledUp = progress.recordCorrect(for: activityName)
        feedback.correct(
            leveledUp ? "Level \(level) unlocked!" : "Shape master!",
            leveledUp: leveledUp,
            then: newRound
        )
    }
}

#Preview {
    NavigationStack {
        ShapesGameView()
    }
    .environment(GameProgress())
}
