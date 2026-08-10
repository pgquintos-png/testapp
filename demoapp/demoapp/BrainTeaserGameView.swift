//
//  BrainTeaserGameView.swift
//  demoapp
//

import SwiftUI
import AVFoundation

struct BrainTeaser {
    let prompt: String
    let sequence: [String]
    let options: [String]
    let answer: String
    let hint: String
    /// Identifies the question so the same one does not come round again straight away.
    let key: String
}

enum BrainTeaserFactory {
    private enum Kind: CaseIterable {
        case pattern, oddOneOut, numberSequence, riddle
    }

    static func random(level: Int, picker: QuestionPicker) -> BrainTeaser {
        switch Kind.allCases.randomElement() ?? .pattern {
        case .pattern: return pattern(level: level)
        case .oddOneOut: return oddOneOut(level: level, picker: picker)
        case .numberSequence: return numberSequence(level: level)
        case .riddle: return riddle(level: level, picker: picker)
        }
    }

    private static let emojiPool = ["🍎", "🍌", "🍇", "⭐", "🐶", "🐱", "🌸", "🎈", "🐝", "🍓", "🐸", "🌻"]

    private static let categories: [[String]] = [
        ["🐶", "🐱", "🐰", "🐸", "🐝"],
        ["🍎", "🍌", "🍇", "🍊", "🍓"],
        ["🚗", "🚌", "🚲", "✈️", "🚂"],
        ["☀️", "🌧️", "❄️", "🌈", "⛈️"],
        ["⚽", "🏀", "🎾", "🏈", "⚾"],
        ["👕", "👖", "🧦", "🧢", "🧣"],
        ["🎹", "🎸", "🥁", "🎻", "🎺"],
    ]

    /// Groups from the same broad topic, so the odd one out takes closer thinking.
    private static let subtleGroups: [(family: [String], intruders: [String], why: String)] = [
        (["🐝", "🦋", "🐞", "🐜"], ["🐶", "🐴", "🐘"], "Count the legs — most of these are bugs."),
        (["🐠", "🐬", "🦈", "🐳"], ["🦁", "🐯", "🐻"], "Think about who lives in the water."),
        (["🍎", "🍌", "🍇", "🍓"], ["🥕", "🥦", "🌽"], "One of these is a vegetable."),
        (["🚗", "🚌", "🚕", "🚚"], ["🚲", "🛴"], "One of these has no engine."),
        (["⚽", "🏀", "🎾", "⚾"], ["🏒", "🎿", "🛷"], "One of these is not a ball."),
        (["🌻", "🌷", "🌹", "🌼"], ["🌵", "🌲", "🍄"], "One of these has no flower."),
        (["🦅", "🦉", "🐦", "🦜"], ["🦇", "🐝", "🦋"], "One of these is not a bird."),
        (["🍞", "🥐", "🥖", "🥯"], ["🍕", "🍜", "🍣"], "Most of these are baked from dough."),
        (["🐄", "🐑", "🐖", "🐔"], ["🦒", "🦓", "🦏"], "Most of these live on a farm."),
        (["🎸", "🎻", "🪕", "🎹"], ["🥁", "🎺", "🪈"], "Most of these have strings."),
    ]

    private static let riddles: [(prompt: String, answer: String, decoys: [String], unlockLevel: Int)] = [
        ("I am yellow, curvy, and monkeys love me. What am I?", "🍌", ["🍎", "🍇", "🥕"], 1),
        ("I have four legs and I say woof. What am I?", "🐶", ["🐱", "🐟", "🐝"], 1),
        ("I shine in the sky during the day. What am I?", "☀️", ["🌙", "⭐", "☁️"], 1),
        ("I am round and you kick me in a game. What am I?", "⚽", ["🎈", "🍪", "📚"], 1),
        ("I buzz around flowers and make honey. What am I?", "🐝", ["🦋", "🐸", "🐧"], 10),
        ("I fly high and carry people far away. What am I?", "✈️", ["🚲", "🚗", "🚂"], 10),
        ("I am cold and white and I fall in winter. What am I?", "❄️", ["🔥", "🌻", "🍁"], 10),
        ("I have black and white stripes like a horse. What am I?", "🦓", ["🐄", "🐴", "🐆"], 10),
        ("I am green, I hop, and I say ribbit. What am I?", "🐸", ["🐢", "🦎", "🐍"], 18),
        ("I am red, round, and crunchy, and I grow on a tree. What am I?", "🍎", ["🍓", "🍒", "🥔"], 18),
        ("I am slimy, I carry my house on my back, and I leave a shiny trail. What am I?", "🐌", ["🐢", "🐜", "🦗"], 25),
        ("I have a very long neck and eat leaves from tall trees. What am I?", "🦒", ["🐘", "🦩", "🐫"], 25),
        ("I am tall, and birds build nests in my leafy branches. What am I?", "🌳", ["🌵", "🍄", "🌾"], 25),
        ("I have eight arms and I live deep in the sea. What am I?", "🐙", ["🦀", "🐠", "🦐"], 32),
        ("I light up the road at night on the front of a car. What am I?", "🚗", ["🚲", "🛴", "🛵"], 32),
        ("I hang upside down when I sleep and I fly at night. What am I?", "🦇", ["🦉", "🐦", "🦅"], 45),
        ("I am full of holes but I still hold water. What am I?", "🧽", ["🪣", "🧴", "🍶"], 45),
        ("I am the biggest animal in the whole ocean. What am I?", "🐳", ["🦈", "🐬", "🐙"], 45),
        ("I change colours and I can walk on walls with sticky feet. What am I?", "🦎", ["🐸", "🐍", "🐢"], 58),
        ("I have a trunk, but I am not a tree. What am I?", "🐘", ["🌳", "🦏", "🐫"], 58),
        ("I have keys but I cannot open any door. What am I?", "🎹", ["🔑", "🚪", "🎸"], 70),
        ("I have a face and two hands but no arms. What am I?", "⌚", ["🧤", "🪞", "🎭"], 70),
        ("I get wetter and wetter the more I dry things. What am I?", "🧻", ["☂️", "🧼", "🪣"], 82),
        ("I go all around the world but I always stay in one corner. What am I?", "📮", ["✈️", "🚢", "🗺️"], 82),
    ]

    private static func optionCount(for level: Int) -> Int {
        Difficulty(level: level).optionCount
    }

    private static func pattern(level: Int) -> BrainTeaser {
        let difficulty = Difficulty(level: level)
        let shuffledPool = emojiPool.shuffled()
        let distinctCount = difficulty.value(from: 2, to: 4, by: 45)

        var cycle = Array(shuffledPool.prefix(distinctCount))
        // Past level 20 the repeat can be uneven, like 🍎 🍎 🍌, which is a harder pattern to hear.
        // Capped at four steps so the sequence can still show two full repeats on one screen.
        if difficulty.has(20) && distinctCount < 4 && Bool.random() {
            cycle.insert(cycle[0], at: 1)
        }

        let cycleLength = cycle.count
        // Always show at least two full repeats, otherwise there is no pattern to spot.
        let extra = cycleLength >= 4 ? 0 : Int.random(in: 0..<cycleLength)
        let shownCount = cycleLength * 2 + extra
        let sequence = (0..<shownCount).map { cycle[$0 % cycleLength] }
        let answer = cycle[shownCount % cycleLength]

        var options = Array(Set(cycle))
        for candidate in shuffledPool where options.count < optionCount(for: level) {
            if !options.contains(candidate) { options.append(candidate) }
        }

        return BrainTeaser(
            prompt: "What comes next?",
            sequence: sequence,
            options: options.shuffled(),
            answer: answer,
            hint: "Say it out loud — the pattern repeats every \(cycleLength)!",
            key: "pattern:\(cycle.joined())"
        )
    }

    private static func oddOneOut(level: Int, picker: QuestionPicker) -> BrainTeaser {
        let difficulty = Difficulty(level: level)
        let wanted = optionCount(for: level)

        if difficulty.has(24) {
            let chosen = picker.choose(from: subtleGroups, key: { "odd:\($0.family.joined())" })
            if let puzzle = chosen {
                let family = puzzle.family.shuffled().prefix(wanted - 1)
                let odd = puzzle.intruders.randomElement() ?? "🐶"
                return BrainTeaser(
                    prompt: "Which one does not belong?",
                    sequence: [],
                    options: (Array(family) + [odd]).shuffled(),
                    answer: odd,
                    hint: puzzle.why,
                    key: "odd:\(puzzle.family.joined())"
                )
            }
        }

        let picked = categories.shuffled()
        let family = picked[0].shuffled().prefix(wanted - 1)
        let odd = picked[1].randomElement() ?? "🐶"

        return BrainTeaser(
            prompt: "Which one does not belong?",
            sequence: [],
            options: (Array(family) + [odd]).shuffled(),
            answer: odd,
            hint: "Three of them are the same kind of thing.",
            key: "odd:\(picked[0].joined())|\(odd)"
        )
    }

    private static func numberSequence(level: Int) -> BrainTeaser {
        let difficulty = Difficulty(level: level)
        let step = Int.random(in: 1...difficulty.value(from: 2, to: 12, by: 70))

        // From level 50 the sequence sometimes counts backwards, starting high enough to stay above zero.
        let countsDown = difficulty.has(50) && Bool.random()
        let signedStep = countsDown ? -step : step
        let start = countsDown
            ? step * 4 + Int.random(in: 1...10)
            : Int.random(in: 1...difficulty.value(from: 10, to: 40, by: 60))
        let answer = start + 4 * signedStep

        var options = [answer]
        var offset = 1
        while options.count < optionCount(for: level) && offset <= 20 {
            for candidate in [answer + offset, answer - offset] where options.count < optionCount(for: level) {
                if candidate > 0 && !options.contains(candidate) { options.append(candidate) }
            }
            offset += 1
        }

        return BrainTeaser(
            prompt: "What number comes next?",
            sequence: (0..<4).map { String(start + $0 * signedStep) },
            options: options.map(String.init).shuffled(),
            answer: String(answer),
            hint: countsDown ? "Each number goes down by \(step)." : "Each number goes up by \(step).",
            key: "seq:\(start)|\(signedStep)"
        )
    }

    private static func riddle(level: Int, picker: QuestionPicker) -> BrainTeaser {
        // Keep the hardest dozen unlocked riddles in play so the questions stay level appropriate
        // rather than sliding back to the very first ones.
        let unlocked = riddles
            .filter { $0.unlockLevel <= level }
            .sorted { $0.unlockLevel < $1.unlockLevel }
        let pool = unlocked.count > 12 ? Array(unlocked.suffix(12)) : unlocked
        guard let picked = picker.choose(from: pool, key: { "riddle:\($0.answer)" }) ?? pool.randomElement() else {
            return pattern(level: level)
        }

        var options = [picked.answer] + picked.decoys
        for other in riddles.shuffled() where options.count < optionCount(for: level) {
            if !options.contains(other.answer) { options.append(other.answer) }
        }

        return BrainTeaser(
            prompt: picked.prompt,
            sequence: [],
            options: options.shuffled(),
            answer: picked.answer,
            hint: "Listen to the clues and picture it in your head.",
            key: "riddle:\(picked.answer)"
        )
    }
}

struct BrainTeaserGameView: View {
    @Environment(GameProgress.self) private var progress

    @State private var puzzle: BrainTeaser?
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var didLevelUp = false
    @State private var wrongTap = false
    @State private var showHint = false
    @State private var streak = 0
    @State private var synthesizer = AVSpeechSynthesizer()

    private let activityName = "Brain Teaser"

    private var level: Int { progress.level(for: activityName) }

    var body: some View {
        ZStack {
            KidTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    LevelBadge(
                        level: level,
                        answersInLevel: progress.answersInCurrentLevel(for: activityName)
                    )

                    if streak > 1 {
                        Text("🔥 \(streak) in a row!")
                            .font(.headline)
                            .foregroundStyle(KidTheme.cardColors[0])
                    }

                    if let puzzle {
                        promptCard(for: puzzle)

                        if !puzzle.sequence.isEmpty {
                            sequenceRow(for: puzzle)
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
        .navigationTitle("Brain Teaser")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newRound() }
        .sensoryFeedback(.success, trigger: showCelebration)
        .sensoryFeedback(.error, trigger: wrongTap)
    }

    private func promptCard(for puzzle: BrainTeaser) -> some View {
        VStack(spacing: 12) {
            Text("🧩")
                .font(.system(size: 44))

            Text(puzzle.prompt)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(KidTheme.headline)

            Button {
                speak(puzzle.prompt)
            } label: {
                Label("Read it to me", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.bordered)
            .tint(KidTheme.cardColors[4])
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

    /// The whole sequence has to be visible at once, so the tiles shrink as the pattern grows.
    private func sequenceRow(for puzzle: BrainTeaser) -> some View {
        let spacing: CGFloat = 6
        let count = CGFloat(puzzle.sequence.count + 1)

        return GeometryReader { proxy in
            let side = min(54, max(26, (proxy.size.width - spacing * (count - 1)) / count))

            HStack(spacing: spacing) {
                ForEach(puzzle.sequence.indices, id: \.self) { index in
                    tile(puzzle.sequence[index], side: side, background: .white)
                }

                tile("?", side: side, background: KidTheme.cardColors[4].opacity(0.25))
            }
            .frame(width: proxy.size.width, alignment: .center)
        }
        .frame(height: 62)
    }

    private func tile(_ label: String, side: CGFloat, background: Color) -> some View {
        Text(label)
            .font(.system(size: side * 0.56, weight: .bold, design: .rounded))
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .foregroundStyle(KidTheme.headline)
            .frame(width: side, height: side)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(background)
                    .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
            )
    }

    private func optionGrid(for puzzle: BrainTeaser) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(Array(puzzle.options.enumerated()), id: \.offset) { index, option in
                Button {
                    check(option, in: puzzle)
                } label: {
                    Text(option)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(KidTheme.cardColors[index % KidTheme.cardColors.count])
                                .shadow(color: .black.opacity(0.15), radius: 5, y: 3)
                        )
                }
                .buttonStyle(KidCardButtonStyle())
            }
        }
    }

    private func hintSection(for puzzle: BrainTeaser) -> some View {
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
                .tint(KidTheme.cardColors[4])
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
            make: { BrainTeaserFactory.random(level: level, picker: picker) },
            key: { $0.key }
        )
        picker.note(next.key)
        puzzle = next
        showHint = false
        showCelebration = false
    }

    private func check(_ answer: String, in puzzle: BrainTeaser) {
        guard answer == puzzle.answer else {
            streak = 0
            wrongTap.toggle()
            return
        }

        streak += 1
        didLevelUp = progress.recordCorrect(for: activityName)
        celebrationMessage = didLevelUp ? "Level \(level) unlocked!" : "Clever thinking!"
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
        BrainTeaserGameView()
    }
    .environment(GameProgress())
}
