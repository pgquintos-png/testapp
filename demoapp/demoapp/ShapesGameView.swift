//
//  ShapesGameView.swift
//  demoapp
//

import SwiftUI

enum ShapeType: String, CaseIterable, Identifiable {
    case circle = "Circle"
    case square = "Square"
    case triangle = "Triangle"
    case star = "Star"
    case heart = "Heart"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .circle: .blue
        case .square: .orange
        case .triangle: .green
        case .star: .yellow
        case .heart: .pink
        }
    }
}

struct ShapeView: View {
    let shape: ShapeType
    var size: CGFloat = 100

    var body: some View {
        switch shape {
        case .circle:
            Circle()
                .fill(shape.color)
                .frame(width: size, height: size)
        case .square:
            RoundedRectangle(cornerRadius: 8)
                .fill(shape.color)
                .frame(width: size, height: size)
        case .triangle:
            Triangle()
                .fill(shape.color)
                .frame(width: size, height: size)
        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.9))
                .foregroundStyle(shape.color)
        case .heart:
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.9))
                .foregroundStyle(shape.color)
        }
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

struct ShapesGameView: View {
    @Environment(GameProgress.self) private var progress

    @State private var targetShape = ShapeType.allCases.randomElement()!
    @State private var options: [ShapeType] = []
    @State private var showCelebration = false
    @State private var wrongTap = false

    var body: some View {
        ZStack {
            KidTheme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Text("What shape is this?")
                    .font(.title.bold())
                    .foregroundStyle(Color(red: 0.2, green: 0.3, blue: 0.5))

                ShapeView(shape: targetShape, size: 120)
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                    )
                    .modifier(ShakeEffect(shakes: wrongTap ? 2 : 0))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(options) { shape in
                        AnswerButton(title: shape.rawValue, color: shape.color) {
                            checkAnswer(shape)
                        }
                    }
                }
            }
            .padding()

            if showCelebration {
                CelebrationOverlay(message: "Shape master!")
            }
        }
        .navigationTitle("Shapes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newRound() }
        .sensoryFeedback(.success, trigger: showCelebration)
        .sensoryFeedback(.error, trigger: wrongTap)
    }

    private func newRound() {
        targetShape = ShapeType.allCases.randomElement()!
        let wrong = ShapeType.allCases.filter { $0 != targetShape }.shuffled()
        options = ([targetShape] + wrong.prefix(3)).shuffled()
        showCelebration = false
    }

    private func checkAnswer(_ answer: ShapeType) {
        if answer == targetShape {
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
        ShapesGameView()
    }
    .environment(GameProgress())
}
