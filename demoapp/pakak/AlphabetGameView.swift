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
        case spellThree         // hear "cat", tap C-A-T
        case spellFour          // hear "fish", tap F-I-S-H
        case spellFive          // hear "apple", tap A-P-P-L-E

        /// Listed in unlock order, so the hardest unlocked styles are the last ones.
        var unlockLevel: Int {
            switch self {
            case .matchUppercase: 1
            case .nearbyLetters: 6
            case .findLowercase: 12
            case .findUppercase: 18
            case .nextLetter: 26
            case .previousLetter: 32
            case .startingSound: 40
            case .spellThree: 50
            case .spellFour: 65
            case .spellFive: 80
            }
        }

        var wordLength: Int? {
            switch self {
            case .spellThree: 3
            case .spellFour: 4
            case .spellFive: 5
            default: nil
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
            case .spellThree, .spellFour, .spellFive: "Spell the word you hear!"
            }
        }

        var caption: String {
            switch self {
            case .startingSound, .spellThree, .spellFour, .spellFive: "Tap the picture to hear it!"
            default: "Tap the letter to hear it!"
            }
        }
    }

    private struct Round {
        let style: QuizStyle
        let promptText: String
        let promptSpeech: String
        let answerLabel: String
        let options: [String]
        let key: String
        /// Set for spelling rounds: the word to build one letter at a time from `options`.
        var word: String? = nil
    }

    @Environment(GameProgress.self) private var progress

    @State private var showQuiz = false
    @State private var selectedLetter: Character?
    @State private var round: Round?
    @State private var feedback = AnswerFeedback()
    @State private var synthesizer = AVSpeechSynthesizer()
    /// The letters of a spelling word tapped correctly so far.
    @State private var spelled = ""
    /// A spelling word forgives one wrong letter before it counts as a miss.
    @State private var slipped = false
    @State private var slipTap = false

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

    private static let spellingWords: [Int: [(emoji: String, word: String)]] = [
        3: [
            ("🐱", "cat"), ("🐶", "dog"), ("☀️", "sun"), ("🚌", "bus"), ("🐷", "pig"),
            ("🐮", "cow"), ("🎩", "hat"), ("🛏️", "bed"), ("🥚", "egg"), ("☕", "cup"),
            ("📦", "box"), ("🦊", "fox"), ("🐝", "bee"), ("🐜", "ant"), ("🦉", "owl"),
            ("🚗", "car"), ("🔑", "key"), ("🦵", "leg"), ("👂", "ear"), ("🦇", "bat"),
            ("🕸️", "web"), ("🗺️", "map"),
        ],
        4: [
            ("🐟", "fish"), ("🐸", "frog"), ("🐻", "bear"), ("🦆", "duck"), ("⚽", "ball"),
            ("🎂", "cake"), ("⭐", "star"), ("🌙", "moon"), ("🌳", "tree"), ("📖", "book"),
            ("⛵", "boat"), ("🪁", "kite"), ("🦁", "lion"), ("🐦", "bird"), ("🥛", "milk"),
            ("🌽", "corn"), ("👟", "shoe"), ("🚪", "door"), ("✋", "hand"), ("💍", "ring"),
            ("🥁", "drum"), ("🐐", "goat"), ("👃", "nose"), ("❄️", "snow"), ("🧦", "sock"),
            ("🔔", "bell"),
        ],
        5: [
            ("🍎", "apple"), ("🏠", "house"), ("🐴", "horse"), ("🐭", "mouse"), ("🐑", "sheep"),
            ("🚂", "train"), ("🦓", "zebra"), ("🐍", "snake"), ("🐯", "tiger"), ("🪑", "chair"),
            ("🕰️", "clock"), ("🍞", "bread"), ("🍇", "grape"), ("🍋", "lemon"), ("🍕", "pizza"),
            ("✈️", "plane"), ("🚚", "truck"), ("🐳", "whale"), ("🦈", "shark"), ("🤖", "robot"),
            ("❤️", "heart"), ("👑", "crown"), ("🧃", "juice"), ("🍬", "candy"), ("🐼", "panda"),
            ("🐫", "camel"), ("🐨", "koala"),
        ],
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

            if let banner = feedback.banner {
                FeedbackOverlay(banner: banner)
            }
        }
        .navigationTitle("Alphabet")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: feedback.rightTap)
        .sensoryFeedback(.error, trigger: feedback.wrongTap)
        .sensoryFeedback(.warning, trigger: slipTap)
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

                if progress.isComplete(for: activityName) {
                    VoucherCard(activity: activityName)
                }

                Text(round.style.instruction)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KidTheme.headline)

                if let word = round.word {
                    spellingSection(word: word, round: round)
                } else {
                    letterQuestion(round)
                }
            }
        } else {
            ProgressView().onAppear { newRound() }
        }
    }

    @ViewBuilder
    private func letterQuestion(_ round: Round) -> some View {
                Text(round.promptText)
                    .font(.system(size: 90, weight: .bold, design: .rounded))
                    .foregroundStyle(KidTheme.cardColors[2])
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.white.opacity(0.7))
                    )
                    .modifier(ShakeEffect(shakes: feedback.wrongTap ? 2 : 0))
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

    @ViewBuilder
    private func spellingSection(word: String, round: Round) -> some View {
        Text(round.promptText)
            .font(.system(size: 80))
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.7))
            )
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title3)
                    .foregroundStyle(KidTheme.cardColors[2])
                    .padding(8)
            }
            .onTapGesture { speak(round.promptSpeech) }

        Text(round.style.caption)
            .font(.caption)
            .foregroundStyle(.secondary)

        HStack(spacing: 8) {
            ForEach(Array(word.uppercased().enumerated()), id: \.offset) { index, letter in
                let filled = index < spelled.count
                Text(filled ? String(letter) : " ")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(KidTheme.headline)
                    .frame(width: 52, height: 62)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(filled ? KidTheme.cardColors[2].opacity(0.35) : .white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                index == spelled.count ? KidTheme.cardColors[2] : .clear,
                                lineWidth: 3
                            )
                    )
            }
        }
        .modifier(ShakeEffect(shakes: slipTap ? 2 : 0))
        .modifier(ShakeEffect(shakes: feedback.wrongTap ? 2 : 0))

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            ForEach(round.options, id: \.self) { option in
                AnswerButton(
                    title: option,
                    color: KidTheme.cardColors[
                        Int(option.unicodeScalars.first?.value ?? 65) % KidTheme.cardColors.count
                    ]
                ) {
                    spell(option, in: round, word: word)
                }
            }
        }
    }

    private func newRound() {
        feedback.clear()
        spelled = ""
        slipped = false

        let picker = QuestionPicker(progress: progress, activity: activityName)
        // Draw from the three hardest styles unlocked so far, which keeps some variety without
        // sliding back to the easiest questions at high levels.
        let styles = Array(unlockedStyles.suffix(3))
        let style = styles.randomElement() ?? .matchUppercase

        if let length = style.wordLength {
            guard let entry = picker.choose(
                from: Self.spellingWords[length] ?? [],
                key: { "\(style.rawValue)|\($0.word)" }
            ) else { return }

            let next = Round(
                style: style,
                promptText: entry.emoji,
                promptSpeech: entry.word,
                answerLabel: entry.word.uppercased(),
                options: letterBank(for: entry.word),
                key: "\(style.rawValue)|\(entry.word)",
                word: entry.word
            )
            picker.note(next.key)
            round = next
            speak("Spell \(entry.word)")
        } else if style == .startingSound {
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
        case .matchUppercase, .startingSound, .spellThree, .spellFour, .spellFive:
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

    /// Every letter in the word plus a few look-alike decoys, so the child has to listen rather than
    /// just use up the tiles. The number of decoys grows with the level like the other games' choices.
    private func letterBank(for word: String) -> [String] {
        let needed = Array(Set(word.uppercased()))
        let decoyCount = difficulty.optionCount - 2
        let pool = needed.flatMap { Self.lookAlikes[$0] ?? [] }.shuffled() + letters.shuffled()

        var decoys: [Character] = []
        for candidate in pool where decoys.count < decoyCount {
            if !needed.contains(candidate) && !decoys.contains(candidate) {
                decoys.append(candidate)
            }
        }
        return (needed + decoys).shuffled().map(String.init)
    }

    private func spell(_ tapped: String, in round: Round, word: String) {
        guard !feedback.isResolving else { return }

        let target = Array(word.uppercased())
        guard spelled.count < target.count else { return }

        guard tapped == String(target[spelled.count]) else {
            if slipped {
                speak(word)
                feedback.wrong("It was \(round.answerLabel).", then: newRound)
            } else {
                slipped = true
                speak("Try again")
                withAnimation(.default) { slipTap.toggle() }
            }
            return
        }

        spelled.append(target[spelled.count])
        guard spelled.count == target.count else {
            speak(tapped)
            return
        }

        let leveledUp = progress.recordCorrect(for: activityName)
        speak("\(target.map(String.init).joined(separator: ", ")). \(word)!")
        feedback.correct(
            progress.celebration(for: activityName, leveledUp: leveledUp, otherwise: "Great spelling!"),
            leveledUp: leveledUp,
            then: newRound
        )
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
        guard !feedback.isResolving else { return }

        guard answer == round.answerLabel else {
            // Saying the letter out loud matters most when the child has just missed it.
            speak(round.answerLabel)
            feedback.wrong("It was \(round.answerLabel).", then: newRound)
            return
        }

        let leveledUp = progress.recordCorrect(for: activityName)
        speak(round.answerLabel)
        feedback.correct(
            progress.celebration(for: activityName, leveledUp: leveledUp, otherwise: "Awesome!"),
            leveledUp: leveledUp,
            then: newRound
        )
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
