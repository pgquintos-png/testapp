//
//  WordRiddleGameView.swift
//  pakak
//

import SwiftUI
import AVFoundation

struct WordPuzzle {
    let prompt: String
    /// Spoken aloud, which differs from the written prompt when letters are missing.
    let spoken: String
    let picture: String?
    let options: [String]
    let answer: String
    let hint: String
    let key: String
}

enum WordPuzzleFactory {
    private enum Kind {
        case rhyme, opposite, oddWord, missingLetter, lateral, wordLength
    }

    static func random(level: Int, picker: QuestionPicker) -> WordPuzzle {
        let difficulty = Difficulty(level: level)
        var kinds: [Kind] = [.rhyme, .opposite]
        if difficulty.has(10) { kinds.append(.oddWord) }
        if difficulty.has(20) { kinds.append(.missingLetter) }
        if difficulty.has(35) { kinds.append(.lateral) }
        if difficulty.has(50) { kinds.append(.wordLength) }

        switch kinds.randomElement() ?? .rhyme {
        case .rhyme: return rhyme(level: level, picker: picker)
        case .opposite: return opposite(level: level, picker: picker)
        case .oddWord: return oddWord(level: level, picker: picker)
        case .missingLetter: return missingLetter(level: level, picker: picker)
        case .lateral: return lateral(level: level, picker: picker)
        case .wordLength: return wordLength(level: level)
        }
    }

    private static let rhymeFamilies: [[String]] = [
        ["cat", "hat", "bat", "mat"],
        ["dog", "log", "frog", "hog"],
        ["sun", "fun", "run", "bun"],
        ["cake", "lake", "rake", "snake"],
        ["star", "car", "jar", "guitar"],
        ["bee", "tree", "knee", "three"],
        ["moon", "spoon", "balloon"],
        ["ball", "tall", "wall", "small"],
        ["light", "night", "kite", "bite"],
        ["chair", "hair", "bear", "pear"],
        ["mouse", "house", "blouse"],
        ["duck", "truck", "luck"],
        ["shell", "bell", "well"],
        ["fish", "dish", "wish"],
        ["clock", "sock", "rock"],
        ["boat", "coat", "goat"],
    ]

    /// Opposites are grouped by topic so a decoy never lands on a rival opposite,
    /// which would make more than one answer defensible.
    private static let opposites: [(topic: String, words: (String, String))] = [
        ("size", ("big", "small")),
        ("size", ("long", "short")),
        ("size", ("high", "low")),
        ("heat", ("hot", "cold")),
        ("way", ("up", "down")),
        ("way", ("in", "out")),
        ("way", ("front", "back")),
        ("time", ("day", "night")),
        ("time", ("old", "new")),
        ("time", ("early", "late")),
        ("mood", ("happy", "sad")),
        ("speed", ("fast", "slow")),
        ("state", ("open", "closed")),
        ("state", ("wet", "dry")),
        ("state", ("full", "empty")),
        ("state", ("clean", "dirty")),
        ("touch", ("hard", "soft")),
        ("touch", ("smooth", "rough")),
        ("bright", ("light", "dark")),
        ("sound", ("loud", "quiet")),
    ]

    private static let wordGroups: [(name: String, words: [String])] = [
        ("an animal", ["cat", "dog", "cow", "pig", "duck"]),
        ("a food", ["apple", "bread", "cake", "rice", "cheese"]),
        ("a colour", ["red", "blue", "green", "yellow", "pink"]),
        ("something you ride in", ["car", "bus", "train", "boat", "plane"]),
        ("a part of your body", ["hand", "foot", "nose", "ear", "knee"]),
        ("something in the sky", ["sun", "cloud", "star", "moon", "rainbow"]),
        ("a number", ["one", "two", "six", "nine", "twelve"]),
        ("something you wear", ["hat", "shoe", "coat", "sock", "glove"]),
    ]

    private static let pictureWords: [(picture: String, word: String)] = [
        ("🐱", "cat"), ("🐶", "dog"), ("☀️", "sun"), ("🌙", "moon"), ("🐟", "fish"),
        ("🎈", "balloon"), ("🍎", "apple"), ("🌟", "star"), ("🚗", "car"), ("🏠", "house"),
        ("🌸", "flower"), ("🐝", "bee"), ("🍰", "cake"), ("🌈", "rainbow"), ("🦁", "lion"),
        ("🐘", "elephant"), ("🦋", "butterfly"), ("☂️", "umbrella"), ("🐧", "penguin"), ("🚂", "train"),
    ]

    private static let lateralRiddles: [(prompt: String, answer: String, decoys: [String], unlockLevel: Int)] = [
        ("What has to be broken before you can use it?", "an egg", ["a cup", "a ball", "a door"], 35),
        ("What kind of room has no doors and no windows?", "a mushroom", ["a bedroom", "a kitchen", "a bathroom"], 35),
        ("What has hands but cannot clap?", "a clock", ["a monkey", "a tree", "a robot"], 35),
        ("What has four legs but cannot walk?", "a table", ["a horse", "a dog", "a spider"], 35),
        ("What can you catch but never throw?", "a cold", ["a fish", "a kite", "a coin"], 50),
        ("What has a neck but no head?", "a bottle", ["a giraffe", "a snake", "a turtle"], 50),
        ("What has one eye but cannot see?", "a needle", ["a cyclops", "a camera", "a potato"], 50),
        ("What has teeth but never eats?", "a comb", ["a shark", "a puppy", "a crocodile"], 62),
        ("The more you take away from me, the bigger I get. What am I?", "a hole", ["a cake", "a box", "a hill"], 62),
        ("What goes up but never comes back down?", "your age", ["a ball", "the rain", "a leaf"], 74),
        ("What has a thumb and four fingers but is not alive?", "a glove", ["a statue", "a robot", "a puppet"], 74),
        ("What can travel all around the world while staying in one corner?", "a stamp", ["a plane", "a ship", "a map"], 86),
    ]

    private static func rhyme(level: Int, picker: QuestionPicker) -> WordPuzzle {
        let wanted = Difficulty(level: level).optionCount
        let candidates = rhymeFamilies.flatMap { family in
            family.map { (target: $0, family: family) }
        }
        guard let picked = picker.choose(from: candidates, key: { "rhyme:\($0.target)" }),
              let answer = picked.family.filter({ $0 != picked.target }).randomElement() else {
            return opposite(level: level, picker: picker)
        }

        var options = [answer]
        for family in rhymeFamilies.shuffled() where options.count < wanted {
            guard !family.contains(picked.target) else { continue }
            if let word = family.randomElement(), !options.contains(word) { options.append(word) }
        }

        return WordPuzzle(
            prompt: "Which word rhymes with \(picked.target.uppercased())?",
            spoken: "Which word rhymes with \(picked.target)?",
            picture: "🎵",
            options: options.shuffled(),
            answer: answer,
            hint: "Say each word out loud. Listen to how it ends.",
            key: "rhyme:\(picked.target)"
        )
    }

    private static func opposite(level: Int, picker: QuestionPicker) -> WordPuzzle {
        let wanted = Difficulty(level: level).optionCount
        let candidates = opposites.flatMap { pair in
            [
                (target: pair.words.0, answer: pair.words.1, topic: pair.topic),
                (target: pair.words.1, answer: pair.words.0, topic: pair.topic),
            ]
        }
        guard let picked = picker.choose(from: candidates, key: { "opp:\($0.target)" }) else {
            return wordLength(level: level)
        }

        var options = [picked.answer]
        let safeDecoys = opposites
            .filter { $0.topic != picked.topic }
            .flatMap { [$0.words.0, $0.words.1] }
            .shuffled()
        for word in safeDecoys where options.count < wanted {
            if !options.contains(word) { options.append(word) }
        }

        return WordPuzzle(
            prompt: "What is the opposite of \(picked.target.uppercased())?",
            spoken: "What is the opposite of \(picked.target)?",
            picture: "🔁",
            options: options.shuffled(),
            answer: picked.answer,
            hint: "Think of the word that means the very other way.",
            key: "opp:\(picked.target)"
        )
    }

    private static func oddWord(level: Int, picker: QuestionPicker) -> WordPuzzle {
        let wanted = Difficulty(level: level).optionCount
        let candidates = wordGroups.flatMap { family in
            wordGroups
                .filter { $0.name != family.name }
                .flatMap(\.words)
                .map { (family: family, intruder: $0) }
        }
        guard let picked = picker.choose(from: candidates, key: { "oddword:\($0.family.name)|\($0.intruder)" }) else {
            return opposite(level: level, picker: picker)
        }

        let keep = picked.family.words.shuffled().prefix(wanted - 1)

        return WordPuzzle(
            prompt: "Which word is NOT \(picked.family.name)?",
            spoken: "Which word is not \(picked.family.name)?",
            picture: "🔍",
            options: (Array(keep) + [picked.intruder]).shuffled(),
            answer: picked.intruder,
            hint: "All of them belong together except one.",
            key: "oddword:\(picked.family.name)|\(picked.intruder)"
        )
    }

    private static func missingLetter(level: Int, picker: QuestionPicker) -> WordPuzzle {
        let difficulty = Difficulty(level: level)
        let wanted = difficulty.optionCount
        // Longer words once the child is well into the game.
        let words = difficulty.has(60)
            ? pictureWords.filter { $0.word.count >= 5 }
            : pictureWords
        let pool = words.isEmpty ? pictureWords : words

        // The first letter stays visible until high levels, so there is always a foothold.
        let candidates = pool.flatMap { entry in
            let lowest = difficulty.has(70) ? 0 : 1
            return (lowest..<entry.word.count).map { (entry: entry, index: $0) }
        }
        guard let picked = picker.choose(from: candidates, key: { "miss:\($0.entry.word)|\($0.index)" }) else {
            return oddWord(level: level, picker: picker)
        }

        let letters = Array(picked.entry.word)
        let missing = String(letters[picked.index])
        let shown = letters.enumerated()
            .map { $0.offset == picked.index ? "_" : String($0.element) }
            .joined(separator: " ")
            .uppercased()

        var options = [missing]
        for letter in Array("abcdefghijklmnopqrstuvwxyz").map(String.init).shuffled() where options.count < wanted {
            if !options.contains(letter) { options.append(letter) }
        }

        return WordPuzzle(
            prompt: "Which letter is missing?\n\(shown)",
            spoken: picked.entry.word,
            picture: picked.entry.picture,
            options: options.shuffled(),
            answer: missing,
            hint: "Say the word slowly and listen for the missing sound.",
            key: "miss:\(picked.entry.word)|\(picked.index)"
        )
    }

    private static func lateral(level: Int, picker: QuestionPicker) -> WordPuzzle {
        let wanted = Difficulty(level: level).optionCount
        let unlocked = lateralRiddles.filter { $0.unlockLevel <= level }
        let pool = unlocked.isEmpty ? lateralRiddles : unlocked
        guard let picked = picker.choose(from: pool, key: { "lat:\($0.answer)" }) else {
            return opposite(level: level, picker: picker)
        }

        var options = [picked.answer] + picked.decoys
        for other in lateralRiddles.shuffled() where options.count < wanted {
            if !options.contains(other.answer) { options.append(other.answer) }
        }

        return WordPuzzle(
            prompt: picked.prompt,
            spoken: picked.prompt,
            picture: "🤔",
            options: options.shuffled(),
            answer: picked.answer,
            hint: "This one is a trick! The words do not mean what you first think.",
            key: "lat:\(picked.answer)"
        )
    }

    /// Compare how long the words are. Every choice has a different number of letters, so the
    /// answer is never a tie.
    private static func wordLength(level: Int) -> WordPuzzle {
        let wanted = Difficulty(level: level).optionCount
        let everyWord = Set(wordGroups.flatMap(\.words) + rhymeFamilies.flatMap { $0 })
        var byLength: [Int: [String]] = [:]
        for word in everyWord {
            byLength[word.count, default: []].append(word)
        }

        let lengths = byLength.keys.shuffled().prefix(wanted)
        let words = lengths.compactMap { byLength[$0]?.randomElement() }
        let asksLongest = Bool.random()
        let answer = (asksLongest ? words.max { $0.count < $1.count } : words.min { $0.count < $1.count }) ?? words[0]

        return WordPuzzle(
            prompt: asksLongest ? "Which word has the MOST letters?" : "Which word has the FEWEST letters?",
            spoken: asksLongest ? "Which word has the most letters?" : "Which word has the fewest letters?",
            picture: "🔤",
            options: words.shuffled(),
            answer: answer,
            hint: "Count the letters in each word with your finger.",
            key: "length:\(asksLongest)|\(words.sorted().joined(separator: ","))"
        )
    }
}

struct WordRiddleGameView: View {
    @Environment(GameProgress.self) private var progress

    @State private var puzzle: WordPuzzle?
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var didLevelUp = false
    @State private var wrongTap = false
    @State private var showHint = false
    @State private var synthesizer = AVSpeechSynthesizer()

    private let activityName = "Word Riddles"

    private var level: Int { progress.level(for: activityName) }

    var body: some View {
        ZStack {
            KidBackdrop()

            ScrollView {
                VStack(spacing: 20) {
                    LevelBadge(
                        level: level,
                        answersInLevel: progress.answersInCurrentLevel(for: activityName)
                    )

                    if let puzzle {
                        promptCard(for: puzzle)
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
        .navigationTitle("Word Riddles")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newRound() }
        .sensoryFeedback(.success, trigger: showCelebration)
        .sensoryFeedback(.error, trigger: wrongTap)
    }

    private func promptCard(for puzzle: WordPuzzle) -> some View {
        VStack(spacing: 12) {
            if let picture = puzzle.picture {
                Text(picture)
                    .font(.system(size: 56))
            }

            Text(puzzle.prompt)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(KidTheme.headline)

            Button {
                speak(puzzle.spoken)
            } label: {
                Label("Read it to me", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.bordered)
            .tint(KidTheme.cardColors[6])
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.7))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        )
        .modifier(ShakeEffect(shakes: wrongTap ? 2 : 0))
    }

    private func optionGrid(for puzzle: WordPuzzle) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(puzzle.options.enumerated()), id: \.offset) { index, option in
                Button {
                    check(option, in: puzzle)
                } label: {
                    Text(option.uppercased())
                        .font(.title3.bold())
                        .minimumScaleFactor(0.6)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(KidTheme.cardColors[index % KidTheme.cardColors.count])
                                .shadow(color: .black.opacity(0.15), radius: 5, y: 3)
                        )
                }
                .buttonStyle(KidCardButtonStyle())
            }
        }
    }

    private func hintSection(for puzzle: WordPuzzle) -> some View {
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
                .tint(KidTheme.cardColors[6])
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
            gap: 20,
            make: { WordPuzzleFactory.random(level: level, picker: picker) },
            key: { $0.key }
        )
        picker.note(next.key)
        puzzle = next
        showHint = false
        showCelebration = false
    }

    private func check(_ answer: String, in puzzle: WordPuzzle) {
        guard answer == puzzle.answer else {
            wrongTap.toggle()
            return
        }

        didLevelUp = progress.recordCorrect(for: activityName)
        celebrationMessage = didLevelUp ? "Level \(level) unlocked!" : "Word wizard!"
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
        WordRiddleGameView()
    }
    .environment(GameProgress())
}
