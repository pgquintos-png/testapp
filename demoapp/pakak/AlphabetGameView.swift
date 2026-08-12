//
//  AlphabetGameView.swift
//  pakak
//

import SwiftUI
import AVFoundation

struct AlphabetGameView: View {
    /// Each style asks about letters in a different way, and they unlock as the level climbs.
    private enum QuizStyle: String, CaseIterable {
        case matchUppercase     // A -> A, unrelated choices
        case nearbyLetters      // A -> A, alphabet neighbours as choices
        case findLowercase      // A -> a
        case findUppercase      // b -> B, look-alike choices
        case nextLetter         // which letter comes after M
        case previousLetter     // which letter comes before M
        case startingSound      // 🍎 -> A

        /// Listed in unlock order, so the hardest unlocked styles are the last ones.
        var unlockLevel: Int {
            switch self {
            case .matchUppercase: 1
            case .nearbyLetters: 10
            case .findLowercase: 22
            case .findUppercase: 34
            case .nextLetter: 46
            case .previousLetter: 58
            case .startingSound: 70
            }
        }

        var instruction: String {
            switch self {
            case .matchUppercase, .nearbyLetters: "Which letter is this?"
            case .findLowercase: "Find the small letter!"
            case .findUppercase: "Find the BIG letter!"
            case .nextLetter: "Which letter comes NEXT?"
            case .previousLetter: "Which letter comes BEFORE?"
            case .startingSound: "Which letter does it start with?"
            }
        }

        var caption: String {
            self == .startingSound ? "Tap the picture to hear it!" : "Tap the letter to hear it!"
        }
    }

    private struct Round {
        let style: QuizStyle
        let promptText: String
        let promptSpeech: String
        let answerLabel: String
        let options: [String]
        let key: String
    }

    @Environment(GameProgress.self) private var progress

    @State private var showQuiz = false
    @State private var selectedLetter: Character?
    @State private var round: Round?
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var didLevelUp = false
    @State private var wrongTap = false
    @State private var synthesizer = AVSpeechSynthesizer()

    private let activityName = "Alphabet"
    private let letters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    private var level: Int { progress.level(for: activityName) }
    private var difficulty: Difficulty { progress.difficulty(for: activityName) }
    private var optionCount: Int { min(difficulty.optionCount, 9) }

    private var unlockedStyles: [QuizStyle] {
        QuizStyle.allCases.filter { $0.unlockLevel <= level }
    }

    private static let lookAlikes: [Character: [Character]] = [
        "A": ["R", "H", "V"], "B": ["D", "P", "R"], "C": ["G", "O", "U"],
        "D": ["B", "O", "P"], "E": ["F", "B", "L"], "F": ["E", "T", "P"],
        "G": ["C", "O", "Q"], "H": ["N", "M", "K"], "I": ["L", "J", "T"],
        "J": ["I", "L", "U"], "K": ["X", "R", "H"], "L": ["I", "J", "T"],
        "M": ["N", "W", "H"], "N": ["M", "H", "W"], "O": ["Q", "G", "D"],
        "P": ["B", "R", "D"], "Q": ["O", "G", "D"], "R": ["P", "B", "K"],
        "S": ["Z", "G", "C"], "T": ["I", "F", "L"], "U": ["V", "W", "Y"],
        "V": ["U", "W", "Y"], "W": ["M", "V", "N"], "X": ["Y", "K", "Z"],
        "Y": ["V", "X", "T"], "Z": ["S", "N", "X"],
    ]

    private static let pictureWords: [(emoji: String, word: String, letter: Character)] = [
        ("🍎", "apple", "A"), ("🎈", "balloon", "B"), ("🐱", "cat", "C"), ("🐶", "dog", "D"),
        ("🥚", "egg", "E"), ("🐟", "fish", "F"), ("🐐", "goat", "G"), ("🏠", "house", "H"),
        ("🍦", "ice cream", "I"), ("🧃", "juice", "J"), ("🪁", "kite", "K"), ("🦁", "lion", "L"),
        ("🌙", "moon", "M"), ("🥜", "nut", "N"), ("🐙", "octopus", "O"), ("🐷", "pig", "P"),
        ("👑", "queen", "Q"), ("🌈", "rainbow", "R"), ("☀️", "sun", "S"), ("🌳", "tree", "T"),
        ("☂️", "umbrella", "U"), ("🎻", "violin", "V"), ("⌚", "watch", "W"), ("🪀", "yo-yo", "Y"),
        ("🦓", "zebra", "Z"),
    ]

    var body: some View {
        ZStack {
            KidBackdrop()

            ScrollView {
                VStack(spacing: 20) {
                    modePicker

                    if showQuiz {
                        quizSection
                    } else {
                        exploreSection
                    }
                }
                .padding()
            }

            if showCelebration {
                CelebrationOverlay(message: celebrationMessage, leveledUp: didLevelUp)
            }
        }
        .navigationTitle("Alphabet")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: showCelebration)
        .sensoryFeedback(.error, trigger: wrongTap)
    }

    private var modePicker: some View {
        Picker("Mode", selection: $showQuiz) {
            Text("Explore").tag(false)
            Text("Quiz").tag(true)
        }
        .pickerStyle(.segmented)
        .onChange(of: showQuiz) { _, isQuiz in
            if isQuiz { newRound() }
        }
    }

    private var exploreSection: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

        return VStack(spacing: 16) {
            Text("Tap a letter to hear it!")
                .font(.title3)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(letters, id: \.self) { letter in
                    Button {
                        speak(String(letter))
                        withAnimation(.spring(response: 0.3)) {
                            selectedLetter = letter
                        }
                    } label: {
                        VStack(spacing: 0) {
                            Text(String(letter))
                                .font(.title2.bold())
                            Text(String(letter).lowercased())
                                .font(.caption)
                        }
                        .foregroundStyle(selectedLetter == letter ? .white : KidTheme.headline)
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedLetter == letter ? KidTheme.cardColors[2] : Color.white)
                                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
                        )
                    }
                    .buttonStyle(KidCardButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var quizSection: some View {
        if let round {
            VStack(spacing: 22) {
                LevelBadge(
                    level: level,
                    answersInLevel: progress.answersInCurrentLevel(for: activityName)
                )

                Text(round.style.instruction)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KidTheme.headline)

                Text(round.promptText)
                    .font(.system(size: 90, weight: .bold, design: .rounded))
                    .foregroundStyle(KidTheme.cardColors[2])
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.white.opacity(0.7))
                    )
                    .modifier(ShakeEffect(shakes: wrongTap ? 2 : 0))
                    .onTapGesture { speak(round.promptSpeech) }

                Text(round.style.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(round.options, id: \.self) { option in
                        AnswerButton(
                            title: option,
                            color: KidTheme.cardColors[
                                Int(option.unicodeScalars.first?.value ?? 65) % KidTheme.cardColors.count
                            ]
                        ) {
                            check(option, in: round)
                        }
                    }
                }
            }
        } else {
            ProgressView().onAppear { newRound() }
        }
    }

    private func newRound() {
        let picker = QuestionPicker(progress: progress, activity: activityName)
        // Draw from the three hardest styles unlocked so far, which keeps some variety without
        // sliding back to the easiest questions at high levels.
        let styles = Array(unlockedStyles.suffix(3))
        let style = styles.randomElement() ?? .matchUppercase

        if style == .startingSound {
            guard let picture = picker.choose(
                from: Self.pictureWords,
                key: { "\(style.rawValue)|\($0.word)" }
            ) else { return }

            let next = Round(
                style: style,
                promptText: picture.emoji,
                promptSpeech: picture.word,
                answerLabel: String(picture.letter),
                options: ([String(picture.letter)] + decoys(for: picture.letter, style: style).map(String.init)).shuffled(),
                key: "\(style.rawValue)|\(picture.word)"
            )
            picker.note(next.key)
            round = next
        } else {
            let subjects = letters.filter { letter in
                switch style {
                case .nextLetter: letter != "Z"
                case .previousLetter: letter != "A"
                default: true
                }
            }
            guard let letter = picker.choose(from: subjects, key: { "\(style.rawValue)|\($0)" }) else { return }

            let next = build(style: style, letter: letter)
            picker.note(next.key)
            round = next
        }

        showCelebration = false
    }

    private func build(style: QuizStyle, letter: Character) -> Round {
        let key = "\(style.rawValue)|\(letter)"
        let decoyLetters = decoys(for: letter, style: style)

        switch style {
        case .findLowercase:
            let answer = String(letter).lowercased()
            return Round(
                style: style,
                promptText: String(letter),
                promptSpeech: String(letter),
                answerLabel: answer,
                options: ([answer] + decoyLetters.map { String($0).lowercased() }).shuffled(),
                key: key
            )
        case .findUppercase:
            return Round(
                style: style,
                promptText: String(letter).lowercased(),
                promptSpeech: String(letter),
                answerLabel: String(letter),
                options: ([String(letter)] + decoyLetters.map(String.init)).shuffled(),
                key: key
            )
        case .nextLetter, .previousLetter:
            let offset = style == .nextLetter ? 1 : -1
            let index = letters.firstIndex(of: letter) ?? 0
            let answer = String(letters[index + offset])
            // The letter on screen is the tempting wrong answer, so it is always offered.
            var options = [answer, String(letter)]
            for decoy in decoyLetters.map(String.init) where options.count < optionCount {
                if !options.contains(decoy) { options.append(decoy) }
            }
            return Round(
                style: style,
                promptText: String(letter),
                promptSpeech: String(letter),
                answerLabel: answer,
                options: options.shuffled(),
                key: key
            )
        default:
            return Round(
                style: style,
                promptText: String(letter),
                promptSpeech: String(letter),
                answerLabel: String(letter),
                options: ([String(letter)] + decoyLetters.map(String.init)).shuffled(),
                key: key
            )
        }
    }

    private func decoys(for letter: Character, style: QuizStyle) -> [Character] {
        var pool: [Character]
        switch style {
        case .matchUppercase, .startingSound:
            pool = letters.shuffled()
        case .nearbyLetters, .nextLetter, .previousLetter:
            pool = neighbours(of: letter) + letters.shuffled()
        case .findLowercase, .findUppercase:
            pool = (Self.lookAlikes[letter] ?? []) + letters.shuffled()
        }

        var chosen: [Character] = []
        for candidate in pool where chosen.count < optionCount - 1 {
            if candidate != letter && !chosen.contains(candidate) {
                chosen.append(candidate)
            }
        }
        return chosen
    }

    private func neighbours(of letter: Character) -> [Character] {
        guard let index = letters.firstIndex(of: letter) else { return [] }
        return [-2, -1, 1, 2]
            .map { index + $0 }
            .filter { letters.indices.contains($0) }
            .map { letters[$0] }
            .shuffled()
    }

    private func check(_ answer: String, in round: Round) {
        guard answer == round.answerLabel else {
            wrongTap.toggle()
            return
        }

        didLevelUp = progress.recordCorrect(for: activityName)
        celebrationMessage = didLevelUp ? "Level \(level) unlocked!" : "Awesome!"
        speak(round.answerLabel)
        withAnimation { showCelebration = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            newRound()
        }
    }

    private func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
}

#Preview {
    NavigationStack {
        AlphabetGameView()
    }
    .environment(GameProgress())
}
