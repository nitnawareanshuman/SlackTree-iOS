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

    @State private var scene = GameScene()

    var body: some View {
        GeometryReader { geometry in
            SpriteView(
                scene: scene,
                options: [.ignoresSiblingOrder]
            )
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .background(Theme.Colors.background)
            .ignoresSafeArea()
            .onAppear {
                scene.scaleMode = .resizeFill
                scene.size = geometry.size
            }
        }
    }
}
