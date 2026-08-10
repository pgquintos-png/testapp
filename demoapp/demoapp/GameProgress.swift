//
//  GameProgress.swift
//  demoapp
//

import SwiftUI

@Observable
final class GameProgress {
    var totalStars: Int = 0

    func earnStar() {
        totalStars += 1
    }
}

struct Activity: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let emoji: String
    let colorIndex: Int
}

let learningActivities: [Activity] = [
    Activity(title: "Counting", subtitle: "How many?", emoji: "🔢", colorIndex: 0),
    Activity(title: "Colors", subtitle: "Find the color!", emoji: "🎨", colorIndex: 1),
    Activity(title: "Alphabet", subtitle: "Learn your ABCs", emoji: "🔤", colorIndex: 2),
    Activity(title: "Shapes", subtitle: "Spot the shape!", emoji: "⭐", colorIndex: 3),
]
