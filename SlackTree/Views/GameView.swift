//
//  GameView.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import SpriteKit
import SwiftUI

struct GameView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var scene: GameScene

    init() {
        _scene = State(initialValue: GameScene())
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Theme.Colors.background
                    .ignoresSafeArea()

                SpriteView(
                    scene: scene,
                    options: [.ignoresSiblingOrder]
                )
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .ignoresSafeArea()

                if gameViewModel.gameState == .playing {
                    GameHUDView(
                        score: gameViewModel.score,
                        onPause: gameViewModel.pauseGame
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if gameViewModel.gameState == .paused {
                    PauseOverlayView(
                        onResume: gameViewModel.resumeGame,
                        onMenu: gameViewModel.returnToMenu
                    )
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(2)
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .onAppear {
                configureScene(size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                scene.size = newSize
            }
            .onChange(of: gameViewModel.gameState) { _, newState in
                scene.isPaused = newState != .playing
            }
            .onChange(of: gameViewModel.gameSessionID) { _, _ in
                // Replace, rather than reuse, the previous SpriteKit scene.
                scene.removeAllActions()
                scene.removeAllChildren()

                let freshScene = GameScene(size: geometry.size)
                freshScene.scaleMode = .resizeFill
                freshScene.gameDelegate = gameViewModel
                scene = freshScene
            }
            .onChange(of: scenePhase) { _, phase in
                // Never resume automatically when the app becomes active.
                if phase != .active {
                    gameViewModel.pauseGame()
                }
            }
            .onDisappear {
                scene.isPaused = true
                scene.gameDelegate = nil
                scene.removeAllActions()
                scene.removeAllChildren()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: gameViewModel.gameState)
    }

    // MARK: - Scene Setup

    private func configureScene(size: CGSize) {
        scene.scaleMode = .resizeFill
        scene.size = size
        scene.gameDelegate = gameViewModel
        scene.isPaused = gameViewModel.gameState != .playing
    }
}

// MARK: - Gameplay HUD

private struct GameHUDView: View {
    let score: Int
    let onPause: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SCORE")
                    .font(.caption2.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.6))

                Text("\(score)")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundStyle(Theme.Colors.text)
            }

            Spacer()

            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.Colors.background)
                    .frame(width: 48, height: 48)
                    .background(
                        Theme.Colors.primary,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .accessibilityLabel("Pause game")
        }
        .padding(18)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Pause Overlay

private struct PauseOverlayView: View {
    let onResume: () -> Void
    let onMenu: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(Theme.Colors.primary)

            Text("PAUSED")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .tracking(3)

            Text("Take a breath. Your tower is waiting.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)

            Button(action: onResume) {
                Label("Resume", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryGameButtonStyle())

            Button(action: onMenu) {
                Text("Main Menu")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryGameButtonStyle())
        }
        .padding(28)
        .frame(maxWidth: 320)
        .foregroundStyle(.white)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.68).ignoresSafeArea())
    }
}

// MARK: - Shared Button Styles

struct PrimaryGameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(Theme.Colors.background)
            .padding(.vertical, 16)
            .background(
                Theme.Colors.primary.opacity(configuration.isPressed ? 0.75 : 1),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryGameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .background(
                .white.opacity(configuration.isPressed ? 0.14 : 0.07),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
    }
}
