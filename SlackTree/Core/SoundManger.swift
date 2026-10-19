//
//  SoundManger.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import AudioToolbox

/// Plays short system sounds without retaining audio players or audio files.
final class SoundManager {
    static let shared = SoundManager()

    private init() {}

    // MARK: - Gameplay Sounds

    func playTap() {
        // Short system click for an ordinary block placement.
        AudioServicesPlaySystemSound(1104)
    }

    func playPerfect() {
        // A brighter confirmation sound for a perfect placement.
        AudioServicesPlaySystemSound(1057)
    }

    func playGameOver() {
        // A short system sound to signal the end of the run.
        AudioServicesPlaySystemSound(1053)
    }

    func stopAll() {
        // No looping players or retained audio resources are used.
    }
}
