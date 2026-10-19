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
    @Published private(set) var gameState: GameState = .menu

    private let highScoreStore: HighScoreStore

    // MARK: - Initialization

    init(highScoreStore: HighScoreStore = .shared) {
        self.highScoreStore = highScoreStore
        self.bestScore = highScoreStore.bestScore
    }

    // MARK: - Game State

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

    func returnToMenu() {
        gameState = .menu
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

    // MARK: - GameSceneDelegate

    func gameScene(_ scene: GameScene, didUpdateScore score: Int) {
        updateScore(score)
    }

    func gameSceneDidEnd(_ scene: GameScene) {
        endGame()
    }
}
