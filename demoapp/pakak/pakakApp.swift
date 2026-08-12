//
//  pakakApp.swift
//  pakak
//
//  Created by Paul Quintos on 8/10/26.
//

import SwiftUI

@main
struct pakakApp: App {
    @State private var progress = GameProgress()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(progress)
        }
    }
}
