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

    /// Retains visible tower blocks, with the highest block last.
    private var placedBlocks: [SKShapeNode] = []

    private var movingBlock: SKShapeNode?
    private var cameraNode: SKCameraNode?

    /// Includes the base block; the base does not count toward player score.
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
        setupCamera()
        spawnMovingBlock()
        updateCameraTarget(animated: false)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        guard size.width > 0 else { return }

        clampMovingBlockToSceneBounds()

        // Recalculate framing immediately when the viewport changes.
        updateCameraTarget(animated: false)
    }

    // MARK: - Setup

    private func setupBaseBlock() {
        removeAllChildren()

        placedBlocks.removeAll(keepingCapacity: true)
        movingBlock = nil
        cameraNode = nil

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

        // The base is structural, not a player-placed block.
        totalPlacedCount = 1
    }

    private func setupCamera() {
        let camera = SKCameraNode()

        camera.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )

        addChild(camera)
        self.camera = camera
        cameraNode = camera
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

        let leftLimit =
            halfWidth + Theme.Gameplay.horizontalInset

        let rightLimit = max(
            leftLimit,
            size.width - halfWidth - Theme.Gameplay.horizontalInset
        )

        // Alternate the starting edge for successive blocks.
        let startsOnRight = nextBlockStartsOnRight
        nextBlockStartsOnRight.toggle()

        moveDirection = startsOnRight ? -1 : 1

        block.position = CGPoint(
            x: startsOnRight ? rightLimit : leftLimit,
            y: topBlock.position.y + Theme.Gameplay.blockHeight
        )

        addChild(block)
        movingBlock = block

        // Follow the new active block rather than shifting the tower.
        updateCameraTarget(animated: true)
    }

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver,
              let block = movingBlock,
              size.width > 0 else {
            lastUpdateTime = currentTime
            return
        }

        // Movement depends on elapsed time, not the number of frames.
        let rawDelta = lastUpdateTime == 0
            ? 0
            : currentTime - lastUpdateTime

        // Prevent a large movement jump after an interruption.
        let deltaTime = min(
            max(rawDelta, 0),
            Theme.Gameplay.maximumFrameDelta
        )

        lastUpdateTime = currentTime

        // Gradually increase speed according to the tower level.
        let level = max(0, totalPlacedCount - 1)

        let requestedSpeed =
            Theme.Gameplay.initialMoveSpeed
            + CGFloat(level) * Theme.Gameplay.speedIncreasePerLevel

        let speed = min(
            requestedSpeed,
            Theme.Gameplay.maximumMoveSpeed
        )

        let halfWidth = block.frame.width / 2

        let leftLimit =
            halfWidth + Theme.Gameplay.horizontalInset

        let rightLimit = max(
            leftLimit,
            size.width - halfWidth - Theme.Gameplay.horizontalInset
        )

        block.position.x += moveDirection * speed * CGFloat(deltaTime)

        // Clamp the block to prevent overshooting at either edge.
        if block.position.x >= rightLimit {
            block.position.x = rightLimit
            moveDirection = -1
        } else if block.position.x <= leftLimit {
            block.position.x = leftLimit
            moveDirection = 1
        }
    }

    private func clampMovingBlockToSceneBounds() {
        guard let block = movingBlock,
              size.width > 0 else {
            return
        }

        let halfWidth = block.frame.width / 2

        let leftLimit =
            halfWidth + Theme.Gameplay.horizontalInset

        let rightLimit = max(
            leftLimit,
            size.width - halfWidth - Theme.Gameplay.horizontalInset
        )

        block.position.x = min(
            max(block.position.x, leftLimit),
            rightLimit
        )
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

        // Intersect the horizontal intervals of the two rectangles.
        let movingLeft =
            moving.position.x - moving.frame.width / 2

        let movingRight =
            moving.position.x + moving.frame.width / 2

        let belowLeft =
            below.position.x - below.frame.width / 2

        let belowRight =
            below.position.x + below.frame.width / 2

        let overlapLeft = max(movingLeft, belowLeft)
        let overlapRight = min(movingRight, belowRight)
        let overlapWidth = overlapRight - overlapLeft

        // Edge-only contact does not count as a successful placement.
        guard overlapWidth > 0 else {
            finishGame()
            return
        }

        let overlapCenterX = (overlapLeft + overlapRight) / 2

        // Trim the block's path to exactly match the overlap.
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

        // Score counts successful player placements, excluding the base.
        let playerScore = totalPlacedCount - 1

        gameDelegate?.gameScene(
            self,
            didUpdateScore: playerScore
        )

        HapticsManager.shared.playSuccess()
        SoundManager.shared.playTap()

        // Spawn first so cleanup uses the next camera target.
        spawnMovingBlock()
        removeOffscreenBlocks()
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

    // MARK: - Camera

    /// Calculates the camera center that places a target at the configured
    /// vertical screen ratio, without changing the tower's world positions.
    private func desiredCameraY(for target: SKNode) -> CGFloat {
        let targetScreenY =
            size.height * Theme.Gameplay.activeBlockScreenYRatio

        return target.position.y
            + size.height / 2
            - targetScreenY
    }

    private func updateCameraTarget(animated: Bool) {
        guard let camera = cameraNode,
              let target = movingBlock ?? placedBlocks.last,
              size.height > 0 else {
            return
        }

        let targetY = desiredCameraY(for: target)

        guard abs(camera.position.y - targetY)
                > Theme.Gameplay.cameraDeadZone else {
            return
        }

        // Starting a new action from the current position keeps camera
        // movement smooth even if another target arrives mid-animation.
        camera.removeAction(forKey: "camera.follow")

        guard animated else {
            camera.position.y = targetY
            return
        }

        let action = SKAction.moveTo(
            y: targetY,
            duration: Theme.Gameplay.cameraFollowDuration
        )

        action.timingMode = .easeInEaseOut

        camera.run(
            action,
            withKey: "camera.follow"
        )
    }

    // MARK: - Node Cleanup

    /// Removes blocks that are below the camera's upcoming visible area.
    private func removeOffscreenBlocks() {
        guard let target = movingBlock ?? placedBlocks.last else {
            return
        }

        let targetCameraY = desiredCameraY(for: target)

        let cutoff = targetCameraY
            - size.height / 2
            - Theme.Gameplay.offscreenCleanupMargin

        let expired = placedBlocks.filter {
            $0.position.y + $0.frame.height / 2 < cutoff
        }

        guard !expired.isEmpty else { return }

        for block in expired {
            block.removeFromParent()
        }

        // Release references as well as removing the SpriteKit nodes.
        placedBlocks.removeAll {
            $0.position.y + $0.frame.height / 2 < cutoff
        }
    }

    // MARK: - Block Colors

    private func blockColor(for level: Int) -> UIColor {
        let palette = Theme.Colors.blockPalette

        return UIColor(
            palette[level % palette.count]
        )
    }
}
