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
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            Group {
                switch gameViewModel.gameState {
                case .menu:
                    MainMenuView(
                        bestScore: gameViewModel.bestScore,
                        onPlay: gameViewModel.startGame
                    )

                case .playing, .paused:
                    GameView()
                        .id(gameViewModel.gameSessionID)

                case .gameOver:
                    GameOverView(
                        score: gameViewModel.score,
                        bestScore: gameViewModel.bestScore,
                        isNewBest: gameViewModel.isNewBest,
                        onRestart: gameViewModel.startGame,
                        onMenu: gameViewModel.returnToMenu
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.3), value: gameViewModel.gameState)
    }
}

// MARK: - Main Menu

private struct MainMenuView: View {
    let bestScore: Int
    let onPlay: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            TowerMarkView()
                .padding(.bottom, 28)

            Text("STACK")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .tracking(5)
                .foregroundStyle(.white)

            Text("TOWER")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .tracking(5)
                .foregroundStyle(Theme.Colors.primary)

            Text("One tap. One more block. How high?")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 12)

            Spacer()

            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Theme.Colors.accentOrange)

                VStack(alignment: .leading, spacing: 3) {
                    Text("PERSONAL BEST")
                        .font(.caption2.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.55))

                    Text("\(bestScore) blocks")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding(18)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
            .padding(.bottom, 18)

            Button(action: onPlay) {
                HStack(spacing: 10) {
                    Text("PLAY")
                        .tracking(2)

                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryGameButtonStyle())

            Text("TAP TO PLACE EACH BLOCK")
                .font(.caption2.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.top, 18)

            Spacer()
                .frame(height: 28)
        }
        .padding(.horizontal, 28)
    }
}

// MARK: - Game Over

private struct GameOverView: View {
    let score: Int
    let bestScore: Int
    let isNewBest: Bool
    let onRestart: () -> Void
    let onMenu: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: isNewBest ? "trophy.fill" : "flag.checkered")
                .font(.system(size: 54))
                .foregroundStyle(
                    isNewBest ? Theme.Colors.accentOrange : Theme.Colors.primary
                )
                .padding(.bottom, 22)

            Text("TOWER ENDED")
                .font(.system(size: 31, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white)

            Text("Every block counts.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
                .padding(.top, 8)

            if isNewBest {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                    Text("NEW BEST!")
                        .tracking(2)
                    Image(systemName: "sparkles")
                }
                .font(.caption.weight(.black))
                .foregroundStyle(Theme.Colors.background)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Theme.Colors.accentOrange,
                    in: Capsule()
                )
                .padding(.top, 22)
                .transition(.scale.combined(with: .opacity))
            }

            HStack(spacing: 12) {
                scoreCard(title: "YOUR SCORE", value: score)
                scoreCard(title: "BEST SCORE", value: bestScore)
            }
            .padding(.top, 28)

            Spacer()

            Button(action: onRestart) {
                Label("Restart", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryGameButtonStyle())

            Button(action: onMenu) {
                Label("Main Menu", systemImage: "house.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryGameButtonStyle())
            .padding(.top, 12)

            Spacer()
                .frame(height: 30)
        }
        .padding(.horizontal, 28)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isNewBest)
    }

    private func scoreCard(title: String, value: Int) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Text("\(value)")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .contentTransition(.numericText())
                .foregroundStyle(Theme.Colors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }
}

// MARK: - Decorative Tower

/// A tiny native-shape illustration keeps the menu asset-free.
private struct TowerMarkView: View {
    private let blockWidths: [CGFloat] = [56, 72, 88, 104]

    var body: some View {
        VStack(spacing: 5) {
            ForEach(Array(blockWidths.enumerated()), id: \.offset) { index, width in
                RoundedRectangle(cornerRadius: 5)
                    .fill(Theme.Colors.blockPalette[index])
                    .frame(width: width, height: 17)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    }
            }
        }
        .shadow(color: Theme.Colors.primary.opacity(0.16), radius: 20)
        .accessibilityHidden(true)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameViewModel())
}
