//
//  GameViewModel.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import Combine
import Foundation

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var score: Int = Theme.Gameplay.initialScore
    @Published private(set) var bestScore: Int
    @Published private(set) var gameState: GameState = .menu

    private let highScoreStore: HighScoreStore

    init(highScoreStore: HighScoreStore = .shared) {
        self.highScoreStore = highScoreStore
        self.bestScore = highScoreStore.bestScore
    }

    func startGame() {
        score = Theme.Gameplay.initialScore
        gameState = .playing
    }

    func pauseGame() {
        guard gameState == .playing else { return }
        gameState = .paused
    }

    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
    }

    func updateScore(_ newScore: Int) {
        guard newScore >= 0 else { return }

        score = newScore

        highScoreStore.saveIfHigher(newScore)
        bestScore = highScoreStore.bestScore
    }

    func endGame() {
        highScoreStore.saveIfHigher(score)
        bestScore = highScoreStore.bestScore
        gameState = .gameOver
    }

    func returnToMenu() {
        gameState = .menu
    }
}
