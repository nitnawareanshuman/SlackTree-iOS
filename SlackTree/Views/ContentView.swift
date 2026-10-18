//
//  ContentView.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel

    var body: some View {
        Group {
            switch gameViewModel.gameState {
            case .menu:
                menuView

            case .playing:
                GameView()

            case .paused:
                GameView()
                    .overlay {
                        pausedOverlay
                    }

            case .gameOver:
                gameOverView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background.ignoresSafeArea())
    }

    private var menuView: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("STACK TOWER")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(Theme.Colors.primary)

            Text("Best: \(gameViewModel.bestScore)")
                .font(.headline)
                .foregroundStyle(Theme.Colors.text.opacity(0.8))

            Button {
                gameViewModel.startGame()
            } label: {
                Text("Start Game")
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.background)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background(
                        Theme.Colors.primary,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }

            Spacer()
        }
        .padding()
    }

    private var pausedOverlay: some View {
        VStack(spacing: 16) {
            Text("PAUSED")
                .font(.largeTitle.bold())

            Button("Resume") {
                gameViewModel.resumeGame()
            }

            Button("Main Menu") {
                gameViewModel.returnToMenu()
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.75))
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Text("GAME OVER")
                .font(.largeTitle.bold())

            Text("Score: \(gameViewModel.score)")
                .font(.title2)

            Text("Best: \(gameViewModel.bestScore)")
                .font(.headline)
                .foregroundStyle(Theme.Colors.primary)

            Button("Play Again") {
                gameViewModel.startGame()
            }

            Button("Main Menu") {
                gameViewModel.returnToMenu()
            }
        }
        .foregroundStyle(.white)
        .padding()
    }
}

#Preview {
    ContentView()
}
