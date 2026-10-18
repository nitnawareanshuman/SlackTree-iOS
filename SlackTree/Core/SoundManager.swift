//
//  SoundManager.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private init() {}

    func playTap() {
        // TODO: Add a short system sound for a successful stack.
    }

    func playGameOver() {
        // TODO: Add a short system sound for game over.
    }

    func stopAll() {
        // TODO: Stop any active audio if looping sounds are added.
    }
}
