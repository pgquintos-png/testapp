//
//  RiddleGameView.swift
//  demoapp
//

import SwiftUI
import AVFoundation

struct RiddleAnswer: Equatable {
    let emoji: String
    let word: String
}

struct Riddle {
    /// The first two clues always identify the answer on their own. Anything after that
    /// is a bonus clue kept back for the hint button.
    let clues: [String]
    let answer: RiddleAnswer
    let decoys: [RiddleAnswer]
    /// The level at which this riddle joins the pool.
    let unlockLevel: Int
}

enum RiddleLibrary {
    static let all: [Riddle] = [
        Riddle(
            clues: ["I am very big and gray.", "I have huge ears and a long trunk.", "I spray water to keep cool."],
            answer: RiddleAnswer(emoji: "🐘", word: "Elephant"),
            decoys: [
                RiddleAnswer(emoji: "🦏", word: "Rhino"),
                RiddleAnswer(emoji: "🐻", word: "Bear"),
                RiddleAnswer(emoji: "🐴", word: "Horse"),
            ],
            unlockLevel: 1
        ),
        Riddle(
            clues: ["I live in the water.", "I have fins and a tail, and I breathe with gills."],
            answer: RiddleAnswer(emoji: "🐟", word: "Fish"),
            decoys: [
                RiddleAnswer(emoji: "🐦", word: "Bird"),
                RiddleAnswer(emoji: "🐰", word: "Rabbit"),
                RiddleAnswer(emoji: "🐝", word: "Bee"),
            ],
            unlockLevel: 1
        ),
        Riddle(
            clues: ["You wear me on your feet.", "I come in a pair and I hide inside your shoes."],
            answer: RiddleAnswer(emoji: "🧦", word: "Socks"),
            decoys: [
                RiddleAnswer(emoji: "🧤", word: "Gloves"),
                RiddleAnswer(emoji: "🎩", word: "Hat"),
                RiddleAnswer(emoji: "🧣", word: "Scarf"),
            ],
            unlockLevel: 1
        ),
        Riddle(
            clues: ["I keep you dry.", "You open me up when it rains.", "I have a handle to hold."],
            answer: RiddleAnswer(emoji: "☂️", word: "Umbrella"),
            decoys: [
                RiddleAnswer(emoji: "🧢", word: "Cap"),
                RiddleAnswer(emoji: "👕", word: "Shirt"),
                RiddleAnswer(emoji: "🪟", word: "Window"),
            ],
            unlockLevel: 8
        ),
        Riddle(
            clues: ["I am orange and crunchy.", "I grow under the ground and rabbits love me."],
            answer: RiddleAnswer(emoji: "🥕", word: "Carrot"),
            decoys: [
                RiddleAnswer(emoji: "🍊", word: "Orange"),
                RiddleAnswer(emoji: "🥔", word: "Potato"),
                RiddleAnswer(emoji: "🌽", word: "Corn"),
            ],
            unlockLevel: 1
        ),
        Riddle(
            clues: ["I have a big furry mane.", "People call me the king of the jungle."],
            answer: RiddleAnswer(emoji: "🦁", word: "Lion"),
            decoys: [
                RiddleAnswer(emoji: "🐯", word: "Tiger"),
                RiddleAnswer(emoji: "🐺", word: "Wolf"),
                RiddleAnswer(emoji: "🐆", word: "Leopard"),
            ],
            unlockLevel: 1
        ),
        Riddle(
            clues: ["I come out at night.", "Sometimes I am a bright circle and sometimes a thin curve."],
            answer: RiddleAnswer(emoji: "🌙", word: "Moon"),
            decoys: [
                RiddleAnswer(emoji: "⭐", word: "Star"),
                RiddleAnswer(emoji: "☀️", word: "Sun"),
                RiddleAnswer(emoji: "☁️", word: "Cloud"),
            ],
            unlockLevel: 20
        ),
        Riddle(
            clues: ["I appear after the rain.", "I am an arc of seven colours in the sky."],
            answer: RiddleAnswer(emoji: "🌈", word: "Rainbow"),
            decoys: [
                RiddleAnswer(emoji: "☁️", word: "Cloud"),
                RiddleAnswer(emoji: "⚡", word: "Lightning"),
                RiddleAnswer(emoji: "❄️", word: "Snow"),
            ],
            unlockLevel: 20
        ),
        Riddle(
            clues: ["I am white and oval with a thin shell.", "A baby chicken grows inside me."],
            answer: RiddleAnswer(emoji: "🥚", word: "Egg"),
            decoys: [
                RiddleAnswer(emoji: "🥔", word: "Potato"),
                RiddleAnswer(emoji: "🧅", word: "Onion"),
                RiddleAnswer(emoji: "🏐", word: "Ball"),
            ],
            unlockLevel: 26
        ),
        Riddle(
            clues: ["I am made of snow with a carrot for a nose.", "I melt away when the sun comes out."],
            answer: RiddleAnswer(emoji: "⛄", word: "Snowman"),
            decoys: [
                RiddleAnswer(emoji: "🧊", word: "Ice"),
                RiddleAnswer(emoji: "🎅", word: "Santa"),
                RiddleAnswer(emoji: "🤖", word: "Robot"),
            ],
            unlockLevel: 26
        ),
        Riddle(
            clues: ["I move slowly on land.", "I have a hard shell I can hide my head inside.", "I can swim well too."],
            answer: RiddleAnswer(emoji: "🐢", word: "Turtle"),
            decoys: [
                RiddleAnswer(emoji: "🦎", word: "Lizard"),
                RiddleAnswer(emoji: "🐸", word: "Frog"),
                RiddleAnswer(emoji: "🐊", word: "Crocodile"),
                RiddleAnswer(emoji: "🐧", word: "Penguin"),
                RiddleAnswer(emoji: "🦀", word: "Crab"),
            ],
            unlockLevel: 45
        ),
        Riddle(
            clues: ["I live in the hot dry desert.", "I am covered in sharp spikes and I store water inside me."],
            answer: RiddleAnswer(emoji: "🌵", word: "Cactus"),
            decoys: [
                RiddleAnswer(emoji: "🌴", word: "Palm tree"),
                RiddleAnswer(emoji: "🌲", word: "Pine tree"),
                RiddleAnswer(emoji: "🌻", word: "Sunflower"),
                RiddleAnswer(emoji: "🍄", word: "Mushroom"),
                RiddleAnswer(emoji: "🌾", word: "Wheat"),
            ],
            unlockLevel: 45
        ),
        Riddle(
            clues: ["I stay awake at night.", "I say hoo hoo and I can turn my head almost all the way around."],
            answer: RiddleAnswer(emoji: "🦉", word: "Owl"),
            decoys: [
                RiddleAnswer(emoji: "🦇", word: "Bat"),
                RiddleAnswer(emoji: "🐦", word: "Bird"),
                RiddleAnswer(emoji: "🦅", word: "Eagle"),
                RiddleAnswer(emoji: "🐔", word: "Chicken"),
                RiddleAnswer(emoji: "🦆", word: "Duck"),
            ],
            unlockLevel: 45
        ),
        Riddle(
            clues: ["I fly high but I am not a bird.", "You hold my string while the wind lifts me up."],
            answer: RiddleAnswer(emoji: "🪁", word: "Kite"),
            decoys: [
                RiddleAnswer(emoji: "🎈", word: "Balloon"),
                RiddleAnswer(emoji: "✈️", word: "Plane"),
                RiddleAnswer(emoji: "🦅", word: "Eagle"),
                RiddleAnswer(emoji: "🚀", word: "Rocket"),
                RiddleAnswer(emoji: "🪂", word: "Parachute"),
            ],
            unlockLevel: 45
        ),
        Riddle(
            clues: ["I am a bird, but I cannot fly at all.", "I waddle on the ice and swim very fast to catch fish."],
            answer: RiddleAnswer(emoji: "🐧", word: "Penguin"),
            decoys: [
                RiddleAnswer(emoji: "🦆", word: "Duck"),
                RiddleAnswer(emoji: "🦢", word: "Swan"),
                RiddleAnswer(emoji: "🐬", word: "Dolphin"),
                RiddleAnswer(emoji: "🦭", word: "Seal"),
                RiddleAnswer(emoji: "🐟", word: "Fish"),
            ],
            unlockLevel: 68
        ),
        Riddle(
            clues: ["I am sweet, sticky and golden.", "Bees make me and bears love to steal me."],
            answer: RiddleAnswer(emoji: "🍯", word: "Honey"),
            decoys: [
                RiddleAnswer(emoji: "🧈", word: "Butter"),
                RiddleAnswer(emoji: "🍬", word: "Candy"),
                RiddleAnswer(emoji: "🥛", word: "Milk"),
                RiddleAnswer(emoji: "🍮", word: "Pudding"),
                RiddleAnswer(emoji: "🧃", word: "Juice"),
            ],
            unlockLevel: 68
        ),
        Riddle(
            clues: ["I have a big fluffy tail.", "I climb trees and hide nuts to eat in the winter."],
            answer: RiddleAnswer(emoji: "🐿️", word: "Squirrel"),
            decoys: [
                RiddleAnswer(emoji: "🐰", word: "Rabbit"),
                RiddleAnswer(emoji: "🐁", word: "Mouse"),
                RiddleAnswer(emoji: "🦔", word: "Hedgehog"),
                RiddleAnswer(emoji: "🦝", word: "Raccoon"),
                RiddleAnswer(emoji: "🦫", word: "Beaver"),
            ],
            unlockLevel: 68
        ),
        Riddle(
            clues: ["You use me every morning and every night.", "I have bristles and I scrub your teeth clean."],
            answer: RiddleAnswer(emoji: "🪥", word: "Toothbrush"),
            decoys: [
                RiddleAnswer(emoji: "🧼", word: "Soap"),
                RiddleAnswer(emoji: "🪮", word: "Comb"),
                RiddleAnswer(emoji: "🍴", word: "Fork"),
                RiddleAnswer(emoji: "🧴", word: "Lotion"),
                RiddleAnswer(emoji: "🧻", word: "Tissue"),
            ],
            unlockLevel: 68
        ),
        Riddle(
            clues: ["I am long and yellow.", "You peel off my skin before you eat me, and monkeys love me."],
            answer: RiddleAnswer(emoji: "🍌", word: "Banana"),
            decoys: [
                RiddleAnswer(emoji: "🍎", word: "Apple"),
                RiddleAnswer(emoji: "🍋", word: "Lemon"),
                RiddleAnswer(emoji: "🍇", word: "Grapes"),
            ],
            unlockLevel: 1
        ),
        Riddle(
            clues: ["I have two wheels.", "You push my pedals and steer me with the handlebars."],
            answer: RiddleAnswer(emoji: "🚲", word: "Bicycle"),
            decoys: [
                RiddleAnswer(emoji: "🚗", word: "Car"),
                RiddleAnswer(emoji: "🛒", word: "Trolley"),
                RiddleAnswer(emoji: "🚂", word: "Train"),
            ],
            unlockLevel: 12
        ),
        Riddle(
            clues: ["I buzz from flower to flower.", "I live in a hive with my sisters and I make honey."],
            answer: RiddleAnswer(emoji: "🐝", word: "Bee"),
            decoys: [
                RiddleAnswer(emoji: "🦋", word: "Butterfly"),
                RiddleAnswer(emoji: "🪰", word: "Fly"),
                RiddleAnswer(emoji: "🐜", word: "Ant"),
            ],
            unlockLevel: 12
        ),
        Riddle(
            clues: ["I hop along on two strong back legs.", "I carry my baby in a pouch on my tummy."],
            answer: RiddleAnswer(emoji: "🦘", word: "Kangaroo"),
            decoys: [
                RiddleAnswer(emoji: "🐰", word: "Rabbit"),
                RiddleAnswer(emoji: "🐸", word: "Frog"),
                RiddleAnswer(emoji: "🐨", word: "Koala"),
                RiddleAnswer(emoji: "🐁", word: "Mouse"),
            ],
            unlockLevel: 34
        ),
        Riddle(
            clues: ["I am full of pages but I am not a tree.", "You turn me over page by page to read a story."],
            answer: RiddleAnswer(emoji: "📖", word: "Book"),
            decoys: [
                RiddleAnswer(emoji: "📰", word: "Newspaper"),
                RiddleAnswer(emoji: "✏️", word: "Pencil"),
                RiddleAnswer(emoji: "📦", word: "Box"),
                RiddleAnswer(emoji: "🖼️", word: "Picture"),
            ],
            unlockLevel: 34
        ),
        Riddle(
            clues: ["I have eight legs.", "I spin a sticky web to catch flies for my dinner."],
            answer: RiddleAnswer(emoji: "🕷️", word: "Spider"),
            decoys: [
                RiddleAnswer(emoji: "🐜", word: "Ant"),
                RiddleAnswer(emoji: "🦀", word: "Crab"),
                RiddleAnswer(emoji: "🐙", word: "Octopus"),
                RiddleAnswer(emoji: "🐞", word: "Ladybug"),
                RiddleAnswer(emoji: "🦗", word: "Cricket"),
            ],
            unlockLevel: 55
        ),
        Riddle(
            clues: ["I carry people across the hot desert sand.", "I have humps on my back and I can go for days without a drink."],
            answer: RiddleAnswer(emoji: "🐫", word: "Camel"),
            decoys: [
                RiddleAnswer(emoji: "🐴", word: "Horse"),
                RiddleAnswer(emoji: "🫏", word: "Donkey"),
                RiddleAnswer(emoji: "🦙", word: "Llama"),
                RiddleAnswer(emoji: "🐘", word: "Elephant"),
                RiddleAnswer(emoji: "🦓", word: "Zebra"),
            ],
            unlockLevel: 55
        ),
        Riddle(
            clues: ["I am a mountain, but sometimes I wake up and roar.", "Hot red rock pours out of the hole in my top."],
            answer: RiddleAnswer(emoji: "🌋", word: "Volcano"),
            decoys: [
                RiddleAnswer(emoji: "⛰️", word: "Mountain"),
                RiddleAnswer(emoji: "🏝️", word: "Island"),
                RiddleAnswer(emoji: "🕳️", word: "Cave"),
                RiddleAnswer(emoji: "🏜️", word: "Desert"),
                RiddleAnswer(emoji: "🧊", word: "Glacier"),
            ],
            unlockLevel: 78
        ),
        Riddle(
            clues: ["I follow you everywhere when the sun is out.", "I copy your shape on the ground, and I vanish in the dark."],
            answer: RiddleAnswer(emoji: "🕴️", word: "Shadow"),
            decoys: [
                RiddleAnswer(emoji: "🪞", word: "Mirror"),
                RiddleAnswer(emoji: "👣", word: "Footprint"),
                RiddleAnswer(emoji: "🔊", word: "Echo"),
                RiddleAnswer(emoji: "💡", word: "Lamp"),
                RiddleAnswer(emoji: "☁️", word: "Cloud"),
            ],
            unlockLevel: 88
        ),
        Riddle(
            clues: ["I come back to you when you shout in a cave.", "I repeat every word you say, but I have no mouth at all."],
            answer: RiddleAnswer(emoji: "🔊", word: "Echo"),
            decoys: [
                RiddleAnswer(emoji: "🕴️", word: "Shadow"),
                RiddleAnswer(emoji: "🪞", word: "Mirror"),
                RiddleAnswer(emoji: "🥁", word: "Drum"),
                RiddleAnswer(emoji: "🎤", word: "Microphone"),
                RiddleAnswer(emoji: "🦜", word: "Parrot"),
            ],
            unlockLevel: 88
        ),
    ]

    static func random(level: Int, picker: QuestionPicker) -> Riddle {
        // Keep the dozen hardest unlocked riddles in rotation, so the clues stay level appropriate
        // instead of drifting back to the very first ones.
        let unlocked = all
            .filter { $0.unlockLevel <= level }
            .sorted { $0.unlockLevel < $1.unlockLevel }
        let pool = unlocked.count > 12 ? Array(unlocked.suffix(12)) : unlocked

        return picker.choose(from: pool, key: { "riddle:\($0.answer.word)" }) ?? all[0]
    }
}

struct RiddleGameView: View {
    @Environment(GameProgress.self) private var progress

    @State private var riddle = RiddleLibrary.all[0]
    @State private var options: [RiddleAnswer] = []
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var didLevelUp = false
    @State private var wrongTap = false
    @State private var showBonusClue = false

    private let activityName = "Riddles"

    private var level: Int { progress.level(for: activityName) }
    private var difficulty: Difficulty { progress.difficulty(for: activityName) }

    /// Early levels lay out every clue. Later on the last clue is held back behind the hint button.
    private var visibleClues: [String] {
        if !difficulty.has(15) || showBonusClue { return riddle.clues }
        return Array(riddle.clues.prefix(2))
    }

    private var hasBonusClue: Bool { riddle.clues.count > 2 && difficulty.has(15) }

    var body: some View {
        ZStack {
            KidTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    LevelBadge(
                        level: level,
                        answersInLevel: progress.answersInCurrentLevel(for: activityName)
                    )

                    clueCard
                    optionGrid

                    if hasBonusClue && !showBonusClue {
                        Button("Give me one more clue") {
                            withAnimation { showBonusClue = true }
                        }
                        .font(.headline)
                        .tint(KidTheme.cardColors[7])
                    }

                    Button {
                        newRound()
                    } label: {
                        Label("Try a different riddle", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                    }
                    .tint(.secondary)
                }
                .padding()
            }

            if showCelebration {
                CelebrationOverlay(message: celebrationMessage, leveledUp: didLevelUp)
            }
        }
        .navigationTitle("Riddles")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newRound() }
        .sensoryFeedback(.success, trigger: showCelebration)
        .sensoryFeedback(.error, trigger: wrongTap)
    }

    private var clueCard: some View {
        VStack(spacing: 14) {
            Text("🕵️")
                .font(.system(size: 44))

            Text("Who am I?")
                .font(.title2.bold())
                .foregroundStyle(KidTheme.headline)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(visibleClues.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.headline)
                            .foregroundStyle(KidTheme.cardColors[7])
                        Text(visibleClues[index])
                            .font(.body)
                            .foregroundStyle(KidTheme.headline)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.7))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        )
        .modifier(ShakeEffect(shakes: wrongTap ? 2 : 0))
    }

    private var optionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    check(option)
                } label: {
                    VStack(spacing: 6) {
                        Text(option.emoji)
                            .font(.system(size: 40))
                        Text(option.word)
                            .font(.subheadline.bold())
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
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

    private func newRound() {
        let picker = QuestionPicker(progress: progress, activity: activityName)
        riddle = RiddleLibrary.random(level: level, picker: picker)
        picker.note("riddle:\(riddle.answer.word)")

        let wanted = min(difficulty.optionCount, riddle.decoys.count + 1)
        options = ([riddle.answer] + riddle.decoys.shuffled().prefix(wanted - 1)).shuffled()
        showBonusClue = false
        showCelebration = false
    }

    private func check(_ answer: RiddleAnswer) {
        guard answer == riddle.answer else {
            wrongTap.toggle()
            return
        }

        didLevelUp = progress.recordCorrect(for: activityName)
        celebrationMessage = didLevelUp ? "Level \(level) unlocked!" : "You solved it!"
        withAnimation { showCelebration = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            newRound()
        }
    }
}

#Preview {
    NavigationStack {
        RiddleGameView()
    }
    .environment(GameProgress())
}
