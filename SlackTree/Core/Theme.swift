//
//  Theme.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import SwiftUI

enum Theme {

    // MARK: - Colors

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

    // MARK: - Gameplay Constants

    enum Gameplay {
        static let targetFPS = 60
        static let initialScore = 0
        static let bestScoreKey = "stackTower.bestScore"

        // Dimensions are in SpriteKit points.
        static let blockWidth: CGFloat = 220
        static let blockHeight: CGFloat = 28
        static let firstBlockCenterY: CGFloat = 110
        static let horizontalInset: CGFloat = 12

        // Movement speed is measured in points per second.
        static let initialMoveSpeed: CGFloat = 250
        static let speedIncreasePerLevel: CGFloat = 8
        static let maximumMoveSpeed: CGFloat = 520

        // Keep the tower's top around 62% of the scene's height.
        static let visibleTowerHeightRatio: CGFloat = 0.62

        // Offscreen nodes can be discarded without affecting the score.
        static let offscreenCleanupMargin: CGFloat = 80

        // Prevent a large update jump following a long pause.
        static let maximumFrameDelta: TimeInterval = 1.0 / 20.0
    }
}
