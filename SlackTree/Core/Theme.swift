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

    // MARK: - Diagnostics

    enum Debug {
        /// SpriteKit counters are enabled for Debug builds only.
        #if DEBUG
        static let showsPerformanceStats = true
        #else
        static let showsPerformanceStats = false
        #endif
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

        // The active block appears in the upper portion of the screen.
        static let activeBlockScreenYRatio: CGFloat = 0.70

        // Camera movement.
        static let cameraFollowDuration: TimeInterval = 0.32
        static let cameraDeadZone: CGFloat = 1.0

        // Remove blocks below the visible camera area plus this margin.
        static let offscreenCleanupMargin: CGFloat = 80

        // Perfect-drop and combo tuning.
        static let perfectDropTolerance: CGFloat = 5
        static let perfectDropBonus = 5
        static let comboBonusPerLevel = 2

        // HSB color progression.
        static let blockHueStart: CGFloat = 0.48
        static let blockHueStep: CGFloat = 0.075
        static let blockHueSaturation: CGFloat = 0.72
        static let blockHueBrightness: CGFloat = 0.96

        // Overhang animation.
        static let overhangFallDuration: TimeInterval = 0.48
        static let overhangFallDistance: CGFloat = 170
        static let overhangFadeDuration: TimeInterval = 0.42

        // Perfect-drop feedback.
        static let perfectFlashDuration: TimeInterval = 0.18
        static let perfectParticleCount = 12
        static let perfectParticleLifetime: CGFloat = 0.32
        static let perfectParticleSpeed: CGFloat = 75
        static let perfectParticleSize: CGFloat = 3.5

        // Prevent large movement jumps after interruptions.
        static let maximumFrameDelta: TimeInterval = 1.0 / 20.0
    }
}
