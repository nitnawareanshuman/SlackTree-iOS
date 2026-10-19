//
//  HighScoreStore.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import Foundation

/// A small UserDefaults wrapper so persistence stays out of gameplay code.
final class HighScoreStore {
    static let shared = HighScoreStore()

    private let defaults: UserDefaults
    private let key = Theme.Gameplay.bestScoreKey

    /// Internal initializer allows isolated UserDefaults suites in tests.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var bestScore: Int {
        max(0, defaults.integer(forKey: key))
    }

    /// Saves only a new record; returns whether this call set a new record.
    @discardableResult
    func saveIfHigher(_ score: Int) -> Bool {
        guard score > bestScore else { return false }

        defaults.set(score, forKey: key)
        return true
    }
}
