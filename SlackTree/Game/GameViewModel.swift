//
//  GameViewModel.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import Combine
import Foundation

@MainActor
final class GameViewModel: ObservableObject, GameSceneDelegate {

    // MARK: - Published State

    @Published private(set) var score: Int = Theme.Gameplay.initialScore
    @Published private(set) var bestScore: Int
    @Published private(set) var combo: Int = 0
    @Published private(set) var gameState: GameState = .menu
    @Published private(set) var isNewBest = false

    /// Incremented to create a fresh SpriteKit scene for a new game.
    @Published private(set) var gameSessionID = UUID()

    private let highScoreStore: HighScoreStore

    // MARK: - Initialization

    init(highScoreStore: HighScoreStore? = nil) {
        let store = highScoreStore ?? HighScoreStore.shared
        self.highScoreStore = store
        self.bestScore = store.bestScore
    }

    // MARK: - State Transitions

    func startGame() {
        score = Theme.Gameplay.initialScore
        combo = 0
        isNewBest = false
        gameSessionID = UUID()
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

    func returnToMenu() {
        // Refresh from storage in case another scene/session recorded a score.
        bestScore = highScoreStore.bestScore
        gameState = .menu
    }

    // MARK: - Score

    func updateScore(_ newScore: Int) {
        guard newScore >= 0 else { return }
        score = newScore

        // Save is deliberately deferred until game over so a run is finalized
        // in one place and an interrupted run cannot write a partial result.
    }

    func endGame() {
        guard gameState == .playing else { return }

        // saveIfHigher both compares and persists, making this the single
        // authoritative point where a completed run can set a personal best.
        isNewBest = highScoreStore.saveIfHigher(score)
        bestScore = highScoreStore.bestScore
        gameState = .gameOver
    }

    // MARK: - GameSceneDelegate

    func gameScene(_ scene: GameScene, didUpdateScore score: Int) {
        guard gameState == .playing else { return }
        updateScore(score)
    }

    func gameScene(_ scene: GameScene, didUpdateCombo combo: Int) {
        guard gameState == .playing else { return }
        self.combo = max(0, combo)
    }

    func gameSceneDidEnd(_ scene: GameScene) {
        guard gameState == .playing else { return }
        endGame()
    }
}
