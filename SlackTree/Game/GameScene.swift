//
//  GameScene.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//

import SpriteKit
import UIKit
import SwiftUI

/// Sends gameplay events to the model without coupling SpriteKit to SwiftUI.
@MainActor
protocol GameSceneDelegate: AnyObject {
    func gameScene(_ scene: GameScene, didUpdateScore score: Int)
    func gameSceneDidEnd(_ scene: GameScene)
}

@MainActor
final class GameScene: SKScene {

    // MARK: - Properties

    weak var gameDelegate: (any GameSceneDelegate)?

    /// Contains currently retained, visible blocks, with the top block last.
    private var placedBlocks: [SKShapeNode] = []

    private var movingBlock: SKShapeNode?
    private var totalPlacedCount = 0

    private var lastUpdateTime: TimeInterval = 0
    private var moveDirection: CGFloat = 1
    private var nextBlockStartsOnRight = false
    private var isGameOver = false
    private var isConfigured = false

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.preferredFramesPerSecond = Theme.Gameplay.targetFPS

        guard !isConfigured else { return }
        isConfigured = true

        setupBaseBlock()
        spawnMovingBlock()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        guard let block = movingBlock, size.width > 0 else { return }

        let halfWidth = block.frame.width / 2
        let leftLimit = halfWidth + Theme.Gameplay.horizontalInset
        let rightLimit = max(
            leftLimit,
            size.width - halfWidth - Theme.Gameplay.horizontalInset
        )

        block.position.x = min(
            max(block.position.x, leftLimit),
            rightLimit
        )
    }

    // MARK: - Setup

    private func setupBaseBlock() {
        removeAllChildren()

        placedBlocks.removeAll(keepingCapacity: true)
        movingBlock = nil
        totalPlacedCount = 0
        lastUpdateTime = 0
        moveDirection = 1
        nextBlockStartsOnRight = false
        isGameOver = false

        let availableWidth = max(
            1,
            size.width - 2 * Theme.Gameplay.horizontalInset
        )

        let baseWidth = min(
            Theme.Gameplay.blockWidth,
            availableWidth
        )

        let base = makeBlock(
            size: CGSize(
                width: baseWidth,
                height: Theme.Gameplay.blockHeight
            ),
            color: UIColor(Theme.Colors.secondary),
            name: "tower.block.placed"
        )

        base.position = CGPoint(
            x: size.width / 2,
            y: Theme.Gameplay.firstBlockCenterY
        )

        addChild(base)
        placedBlocks.append(base)
        totalPlacedCount = 1
    }

    private func makeBlock(
        size blockSize: CGSize,
        color: UIColor,
        name: String
    ) -> SKShapeNode {
        let block = SKShapeNode(rectOf: blockSize)
        block.fillColor = color
        block.strokeColor = color
        block.lineWidth = 0
        block.name = name

        return block
    }

    // MARK: - Moving Block

    private func spawnMovingBlock() {
        guard let topBlock = placedBlocks.last,
              size.width > 0,
              !isGameOver else {
            return
        }

        let blockSize = CGSize(
            width: topBlock.frame.width,
            height: Theme.Gameplay.blockHeight
        )

        let block = makeBlock(
            size: blockSize,
            color: blockColor(for: totalPlacedCount),
            name: "tower.block.moving"
        )

        let halfWidth = blockSize.width / 2
        let leftLimit = halfWidth + Theme.Gameplay.horizontalInset
        let rightLimit = max(
            leftLimit,
            size.width - halfWidth - Theme.Gameplay.horizontalInset
        )

        // Alternate the edge at which each new block begins.
        let startsOnRight = nextBlockStartsOnRight
        nextBlockStartsOnRight.toggle()

        moveDirection = startsOnRight ? -1 : 1

        block.position = CGPoint(
            x: startsOnRight ? rightLimit : leftLimit,
            y: topBlock.position.y + Theme.Gameplay.blockHeight
        )

        addChild(block)
        movingBlock = block
    }

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver,
              let block = movingBlock,
              size.width > 0 else {
            lastUpdateTime = currentTime
            return
        }

        // Use elapsed time rather than a fixed per-frame movement amount.
        let rawDelta = lastUpdateTime == 0
            ? 0
            : currentTime - lastUpdateTime

        // Avoid large jumps after a debugger pause or app interruption.
        let deltaTime = min(
            max(rawDelta, 0),
            Theme.Gameplay.maximumFrameDelta
        )

        lastUpdateTime = currentTime

        let level = max(0, totalPlacedCount - 1)
        let requestedSpeed =
            Theme.Gameplay.initialMoveSpeed
            + CGFloat(level) * Theme.Gameplay.speedIncreasePerLevel

        let speed = min(
            requestedSpeed,
            Theme.Gameplay.maximumMoveSpeed
        )

        let halfWidth = block.frame.width / 2
        let leftLimit = halfWidth + Theme.Gameplay.horizontalInset
        let rightLimit = max(
            leftLimit,
            size.width - halfWidth - Theme.Gameplay.horizontalInset
        )

        block.position.x += moveDirection * speed * CGFloat(deltaTime)

        // Clamp at the boundary to prevent overshooting between frames.
        if block.position.x >= rightLimit {
            block.position.x = rightLimit
            moveDirection = -1
        } else if block.position.x <= leftLimit {
            block.position.x = leftLimit
            moveDirection = 1
        }
    }

    // MARK: - Input and Overlap

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesBegan(touches, with: event)
        dropMovingBlock()
    }

    private func dropMovingBlock() {
        guard !isGameOver,
              let moving = movingBlock,
              let below = placedBlocks.last else {
            return
        }

        // Both rectangles are axis-aligned, so only their X intervals
        // are needed to determine the width of their intersection.
        let movingLeft = moving.position.x - moving.frame.width / 2
        let movingRight = moving.position.x + moving.frame.width / 2

        let belowLeft = below.position.x - below.frame.width / 2
        let belowRight = below.position.x + below.frame.width / 2

        let overlapLeft = max(movingLeft, belowLeft)
        let overlapRight = min(movingRight, belowRight)
        let overlapWidth = overlapRight - overlapLeft

        // Merely touching at an edge is not a valid overlap.
        guard overlapWidth > 0 else {
            finishGame()
            return
        }

        let overlapCenterX = (overlapLeft + overlapRight) / 2

        // Replace the local rectangle path with the exact intersection.
        // The path is centered around the node's local origin.
        let trimmedRect = CGRect(
            x: -overlapWidth / 2,
            y: -Theme.Gameplay.blockHeight / 2,
            width: overlapWidth,
            height: Theme.Gameplay.blockHeight
        )

        moving.path = CGPath(
            rect: trimmedRect,
            transform: nil
        )

        moving.position.x = overlapCenterX
        moving.name = "tower.block.placed"
        moving.fillColor = blockColor(for: totalPlacedCount)
        moving.strokeColor = moving.fillColor

        placedBlocks.append(moving)
        totalPlacedCount += 1
        movingBlock = nil

        // Score counts successful placements above the base block.
        gameDelegate?.gameScene(
            self,
            didUpdateScore: totalPlacedCount - 1
        )

        HapticsManager.shared.playSuccess()
        SoundManager.shared.playTap()

        keepTowerInView()
        removeOffscreenBlocks()
        spawnMovingBlock()
    }

    private func finishGame() {
        guard !isGameOver else { return }

        isGameOver = true
        movingBlock?.removeFromParent()
        movingBlock = nil

        HapticsManager.shared.playFailure()
        SoundManager.shared.playGameOver()

        gameDelegate?.gameSceneDidEnd(self)
    }

    // MARK: - Tower Position and Cleanup

    /// Moves the tower downward as it grows so the latest block stays visible.
    private func keepTowerInView() {
        guard let topBlock = placedBlocks.last else { return }

        let targetY = size.height * Theme.Gameplay.visibleTowerHeightRatio
        let shift = targetY - topBlock.position.y

        guard shift < 0 else { return }

        for block in placedBlocks {
            block.position.y += shift
        }
    }

    /// Drops references to blocks that have completely left the bottom of the view.
    private func removeOffscreenBlocks() {
        let cutoff = -Theme.Gameplay.offscreenCleanupMargin

        let expired = placedBlocks.filter {
            $0.position.y + $0.frame.height / 2 < cutoff
        }

        guard !expired.isEmpty else { return }

        for block in expired {
            block.removeFromParent()
        }

        placedBlocks.removeAll { $0.position.y + $0.frame.height / 2 < cutoff }
    }

    private func blockColor(for level: Int) -> UIColor {
        let palette: [UIColor] = [
            UIColor(Theme.Colors.primary),
            UIColor(Theme.Colors.secondary),
            UIColor(
                red: 1.0,
                green: 0.67,
                blue: 0.42,
                alpha: 1.0
            ),
            UIColor(
                red: 0.95,
                green: 0.44,
                blue: 0.62,
                alpha: 1.0
            )
        ]

        return palette[level % palette.count]
    }
}
