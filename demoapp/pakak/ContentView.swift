//
//  ContentView.swift
//  pakak
//
//  Created by Paul Quintos on 8/10/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environment(GameProgress())
}
