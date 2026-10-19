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

        static let accentOrange = Color(
            red: 1.0,
            green: 0.67,
            blue: 0.42
        )

        static let accentPink = Color(
            red: 0.95,
            green: 0.44,
            blue: 0.62
        )

        static let text = Color.white

        static let blockPalette: [Color] = [
            primary,
            secondary,
            accentOrange,
            accentPink
        ]
    }

    // MARK: - Gameplay Constants

    enum Gameplay {
        static let targetFPS = 60
        static let initialScore = 0
        static let bestScoreKey = "stackTower.bestScore"

        // Dimensions are measured in SpriteKit points.
        static let blockWidth: CGFloat = 220
        static let blockHeight: CGFloat = 28
        static let firstBlockCenterY: CGFloat = 110
        static let horizontalInset: CGFloat = 12

        // Horizontal movement speed, in points per second.
        static let initialMoveSpeed: CGFloat = 250
        static let speedIncreasePerLevel: CGFloat = 8
        static let maximumMoveSpeed: CGFloat = 520

        // The target block appears 70% of the way up the screen.
        static let activeBlockScreenYRatio: CGFloat = 0.70

        // Smooth camera-follow animation.
        static let cameraFollowDuration: TimeInterval = 0.32
        static let cameraDeadZone: CGFloat = 1.0

        // Remove blocks below the visible camera area plus this margin.
        static let offscreenCleanupMargin: CGFloat = 80

        // Limit movement after a pause or unusually long frame.
        static let maximumFrameDelta: TimeInterval = 1.0 / 20.0
    }
}
