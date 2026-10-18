//
//  HighScoreStore.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import Foundation

final class HighScoreStore {
    static let shared = HighScoreStore()

    private let defaults: UserDefaults
    private let key = Theme.Gameplay.bestScoreKey

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var bestScore: Int {
        defaults.integer(forKey: key)
    }

    func saveIfHigher(_ score: Int) {
        guard score > bestScore else { return }
        defaults.set(score, forKey: key)
    }
}
