//
//  SlackTreeApp.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import SwiftUI

@main
struct StackTowerApp: App {
    @StateObject private var gameViewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
