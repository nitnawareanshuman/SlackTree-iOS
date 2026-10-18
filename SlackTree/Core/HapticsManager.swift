//
//  HapticsManager.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import UIKit

final class HapticsManager {
    static let shared = HapticsManager()

    private init() {}

    func playTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    func playFailure() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}
