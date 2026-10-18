//
//  Theme.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import SwiftUI

enum Theme {
    enum Colors {
        static let background = Color(
            red: 0.055,
            green: 0.067,
            blue: 0.12
        )

        static let primary = Color(
            red: 0.36,
            green: 0.88,
            blue: 0.82
        )

        static let secondary = Color(
            red: 0.55,
            green: 0.48,
            blue: 0.95
        )

        static let text = Color.white
    }

    enum Gameplay {
        static let targetFPS = 60
        static let initialScore = 0
        static let bestScoreKey = "stackTower.bestScore"
    }
}
