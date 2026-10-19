//
//  GameScene.swift
//  SlackTree
//
//  Created by Anshuman Nitnaware on 19/10/26.
//


import SpriteKit
import SwiftUI
import UIKit

/// Sends gameplay updates to the SwiftUI-facing model.
@MainActor
protocol GameSceneDelegate: AnyObject {
    func gameScene(_ scene: GameScene, didUpdateScore score: Int)
    func gameScene(_ scene: GameScene, didUpdateCombo combo: Int)
    func gameSceneDidEnd(_ scene: GameScene)
}

@MainActor
final class GameScene: SKScene {

    // MARK: - Properties

    weak var gameDelegate: (any GameSceneDelegate)?

    /// The highest placed block is always the final element.
    private var placedBlocks: [SKShapeNode] = []

    private var movingBlock: SKShapeNode?
    private var cameraNode: SKCameraNode?

    /// Includes the base block, which does not count as a player placement.
    private var totalPlacedCount = 0

    private var currentScore = 0
    private var comboCount = 0

    private var lastUpdateTime: TimeInterval = 0
    private var moveDirection: CGFloat = 1
    private var nextBlockStartsOnRight = false
    private var isGameOver = false
    private var isConfigured = false

    // Cached per-block movement values keep update() limited to scalar math.
    private var movementLeftLimit: CGFloat = 0
    private var movementRightLimit: CGFloat = 0
    private var currentMoveSpeed: CGFloat = Theme.Gameplay.initialMoveSpeed

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.preferredFramesPerSecond = Theme.Gameplay.targetFPS
        view.showsFPS = Theme.Debug.showsPerformanceStats
        view.showsNodeCount = Theme.Debug.showsPerformanceStats

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
        updateCameraTarget(animated: false)
    }

    // MARK: - Setup

    private func setupBaseBlock() {
        removeAllChildren()

        placedBlocks.removeAll(keepingCapacity: true)
        movingBlock = nil
        cameraNode = nil

        totalPlacedCount = 0
        currentScore = 0
        comboCount = 0

        lastUpdateTime = 0
        moveDirection = 1
        nextBlockStartsOnRight = false
        isGameOver = false
        movementLeftLimit = 0
        movementRightLimit = 0
        currentMoveSpeed = Theme.Gameplay.initialMoveSpeed

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

        updateMovementBounds(for: block)
        updateMovementSpeed()

        let startsOnRight = nextBlockStartsOnRight
        nextBlockStartsOnRight.toggle()
        moveDirection = startsOnRight ? -1 : 1

        block.position = CGPoint(
            x: startsOnRight ? movementRightLimit : movementLeftLimit,
            y: topBlock.position.y + Theme.Gameplay.blockHeight
        )

        addChild(block)
        movingBlock = block

        updateCameraTarget(animated: true)
    }

    /// Recomputed only when a block spawns or the scene dimensions change.
    private func updateMovementBounds(for block: SKShapeNode) {
        let halfWidth = block.frame.width / 2
        movementLeftLimit = halfWidth + Theme.Gameplay.horizontalInset
        movementRightLimit = max(
            movementLeftLimit,
            size.width - halfWidth - Theme.Gameplay.horizontalInset
        )
    }

    /// Difficulty changes once per spawned block, not every frame.
    private func updateMovementSpeed() {
        let level = max(0, totalPlacedCount - 1)
        let requestedSpeed = Theme.Gameplay.initialMoveSpeed
            + CGFloat(level) * Theme.Gameplay.speedIncreasePerLevel
        currentMoveSpeed = min(
            requestedSpeed,
            Theme.Gameplay.maximumMoveSpeed
        )
    }

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver,
              let block = movingBlock,
              size.width > 0 else {
            lastUpdateTime = currentTime
            return
        }

        // Only scalar value math occurs here; no arrays, nodes, or actions are made.
        let rawDelta = lastUpdateTime == 0
            ? 0
            : currentTime - lastUpdateTime
        let deltaTime = min(
            max(rawDelta, 0),
            Theme.Gameplay.maximumFrameDelta
        )
        lastUpdateTime = currentTime

        block.position.x += moveDirection * currentMoveSpeed * CGFloat(deltaTime)

        if block.position.x >= movementRightLimit {
            block.position.x = movementRightLimit
            moveDirection = -1
        } else if block.position.x <= movementLeftLimit {
            block.position.x = movementLeftLimit
            moveDirection = 1
        }
    }

    private func clampMovingBlockToSceneBounds() {
        guard let block = movingBlock,
              size.width > 0 else {
            return
        }

        updateMovementBounds(for: block)
        block.position.x = min(
            max(block.position.x, movementLeftLimit),
            movementRightLimit
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

        let originalWidth = moving.frame.width
        let halfWidth = originalWidth / 2

        let movingLeft = moving.position.x - halfWidth
        let movingRight = moving.position.x + halfWidth

        let belowLeft = below.position.x - below.frame.width / 2
        let belowRight = below.position.x + below.frame.width / 2

        // A near-perfect alignment snaps directly to the block underneath.
        let isPerfect = abs(
            moving.position.x - below.position.x
        ) <= Theme.Gameplay.perfectDropTolerance

        let overlapLeft = max(movingLeft, belowLeft)
        let overlapRight = min(movingRight, belowRight)
        let overlapWidth = overlapRight - overlapLeft

        // Edge-only contact is not a valid placement.
        guard isPerfect || overlapWidth > 0 else {
            finishGame()
            return
        }

        let finalWidth: CGFloat
        let finalCenterX: CGFloat

        if isPerfect {
            finalWidth = below.frame.width
            finalCenterX = below.position.x
        } else {
            finalWidth = overlapWidth
            finalCenterX = (overlapLeft + overlapRight) / 2

            // Preserve the discarded section as an independent falling node.
            spawnOverhangs(
                movingLeft: movingLeft,
                movingRight: movingRight,
                overlapLeft: overlapLeft,
                overlapRight: overlapRight,
                y: moving.position.y,
                color: moving.fillColor
            )
        }

        let finalSize = CGSize(
            width: finalWidth,
            height: Theme.Gameplay.blockHeight
        )

        moving.path = CGPath(
            rect: CGRect(
                x: -finalWidth / 2,
                y: -Theme.Gameplay.blockHeight / 2,
                width: finalWidth,
                height: Theme.Gameplay.blockHeight
            ),
            transform: nil
        )

        moving.position.x = finalCenterX
        moving.name = "tower.block.placed"
        moving.fillColor = blockColor(for: totalPlacedCount)
        moving.strokeColor = moving.fillColor

        placedBlocks.append(moving)
        totalPlacedCount += 1
        movingBlock = nil

        // Consecutive perfect placements build a combo; any miss breaks it.
        let bonus: Int

        if isPerfect {
            comboCount += 1

            bonus = Theme.Gameplay.perfectDropBonus
                + (comboCount - 1) * Theme.Gameplay.comboBonusPerLevel

            showPerfectEffect(
                at: CGPoint(
                    x: finalCenterX,
                    y: moving.position.y
                ),
                blockSize: finalSize,
                color: moving.fillColor
            )

            HapticsManager.shared.playSuccess()
            SoundManager.shared.playPerfect()
        } else {
            comboCount = 0
            bonus = 0

            HapticsManager.shared.playTap()
            SoundManager.shared.playTap()
        }

        // The ordinary placement earns one point; perfect drops add a bonus.
        currentScore += 1 + bonus

        gameDelegate?.gameScene(
            self,
            didUpdateScore: currentScore
        )

        gameDelegate?.gameScene(
            self,
            didUpdateCombo: comboCount
        )

        spawnMovingBlock()
        removeOffscreenBlocks()
    }

    // MARK: - Overhang Animation

    /// Creates only the discarded portions, then removes them after they fall.
    private func spawnOverhangs(
        movingLeft: CGFloat,
        movingRight: CGFloat,
        overlapLeft: CGFloat,
        overlapRight: CGFloat,
        y: CGFloat,
        color: UIColor
    ) {
        if overlapLeft > movingLeft {
            spawnOverhang(
                fromX: movingLeft,
                toX: overlapLeft,
                y: y,
                color: color,
                horizontalDirection: -1
            )
        }

        if movingRight > overlapRight {
            spawnOverhang(
                fromX: overlapRight,
                toX: movingRight,
                y: y,
                color: color,
                horizontalDirection: 1
            )
        }
    }

    private func spawnOverhang(
        fromX startX: CGFloat,
        toX endX: CGFloat,
        y: CGFloat,
        color: UIColor,
        horizontalDirection: CGFloat
    ) {
        let pieceWidth = endX - startX
        guard pieceWidth > 0 else { return }

        let piece = makeBlock(
            size: CGSize(
                width: pieceWidth,
                height: Theme.Gameplay.blockHeight
            ),
            color: color,
            name: "tower.block.overhang"
        )

        piece.position = CGPoint(
            x: (startX + endX) / 2,
            y: y
        )
        piece.zPosition = 5
        addChild(piece)

        // SpriteKit actions animate the fragment without per-frame bookkeeping.
        let fall = SKAction.moveBy(
            x: horizontalDirection * pieceWidth * 0.25,
            y: -Theme.Gameplay.overhangFallDistance,
            duration: Theme.Gameplay.overhangFallDuration
        )
        fall.timingMode = .easeIn

        let fade = SKAction.fadeOut(
            withDuration: Theme.Gameplay.overhangFadeDuration
        )
        let finish = SKAction.group([fall, fade])

        piece.run(
            SKAction.sequence([
                finish,
                SKAction.removeFromParent()
            ]),
            withKey: "overhang.fallAndRemove"
        )
    }

    // MARK: - Perfect-Drop Effects

    private func showPerfectEffect(
        at position: CGPoint,
        blockSize: CGSize,
        color: UIColor
    ) {
        // A single translucent rectangle gives a quick alignment flash.
        let flash = SKShapeNode(rectOf: blockSize)
        flash.position = position
        flash.fillColor = .white
        flash.strokeColor = .white
        flash.lineWidth = 0
        flash.alpha = 0.75
        flash.zPosition = 20
        flash.blendMode = .add
        addChild(flash)

        flash.run(
            SKAction.sequence([
                SKAction.fadeOut(
                    withDuration: Theme.Gameplay.perfectFlashDuration
                ),
                SKAction.removeFromParent()
            ]),
            withKey: "perfect.flash"
        )

        // The particle burst is intentionally short-lived and asset-free.
        let count = Theme.Gameplay.perfectParticleCount
        for index in 0..<count {
            let angle = CGFloat.pi * 2
                * CGFloat(index) / CGFloat(count)

            let particle = SKShapeNode(
                ellipseOf: CGSize(
                    width: Theme.Gameplay.perfectParticleSize,
                    height: Theme.Gameplay.perfectParticleSize
                )
            )
            particle.fillColor = color
            particle.strokeColor = color
            particle.lineWidth = 0
            particle.position = position
            particle.zPosition = 21
            addChild(particle)

            let distance = Theme.Gameplay.perfectParticleSpeed
            let destinationX = cos(angle) * distance
            let destinationY = sin(angle) * distance

            let travel = SKAction.moveBy(
                x: destinationX,
                y: destinationY,
                duration: TimeInterval(
                    Theme.Gameplay.perfectParticleLifetime
                )
            )
            let fade = SKAction.fadeOut(
                withDuration: TimeInterval(
                    Theme.Gameplay.perfectParticleLifetime
                )
            )

            particle.run(
                SKAction.sequence([
                    SKAction.group([travel, fade]),
                    SKAction.removeFromParent()
                ]),
                withKey: "perfect.particle"
            )
        }
    }

    // MARK: - Game Over

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

    /// Places the active block at the configured vertical screen ratio.
    private func desiredCameraY(for target: SKNode) -> CGFloat {
        let targetScreenY = size.height * Theme.Gameplay.activeBlockScreenYRatio
        return target.position.y + size.height / 2 - targetScreenY
    }

    private func updateCameraTarget(animated: Bool) {
        guard let camera = cameraNode,
              let target = movingBlock ?? placedBlocks.last,
              size.height > 0 else {
            return
        }

        let targetY = desiredCameraY(for: target)
        guard abs(camera.position.y - targetY) > Theme.Gameplay.cameraDeadZone else {
            return
        }

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
        camera.run(action, withKey: "camera.follow")
    }

    // MARK: - Node Cleanup

    /// Removes the oldest blocks once they are below the camera's lower edge.
    /// The stack is ordered by height, so culling is a prefix scan with no
    /// temporary filtered arrays. SpriteKit actions also remove all effects.
    private func removeOffscreenBlocks() {
        guard let target = movingBlock ?? placedBlocks.last else { return }

        let targetCameraY = desiredCameraY(for: target)
        let cutoff = targetCameraY
            - size.height / 2
            - Theme.Gameplay.offscreenCleanupMargin

        var expiredCount = 0
        while expiredCount < placedBlocks.count {
            let block = placedBlocks[expiredCount]
            let blockTop = block.position.y + Theme.Gameplay.blockHeight / 2
            guard blockTop < cutoff else { break }

            block.removeFromParent()
            expiredCount += 1
        }

        // Array.removeFirst keeps the retained tail and releases old references.
        // The retained stack is bounded by the visible camera window.
        if expiredCount > 0 {
            placedBlocks.removeFirst(expiredCount)
        }
    }

    // MARK: - Block Colors

    /// Wraps through the hue wheel while keeping saturation and brightness fixed.
    private func blockColor(for level: Int) -> UIColor {
        let hue = (
            Theme.Gameplay.blockHueStart
                + CGFloat(level) * Theme.Gameplay.blockHueStep
        ).truncatingRemainder(dividingBy: 1.0)

        return UIColor(
            hue: hue,
            saturation: Theme.Gameplay.blockHueSaturation,
            brightness: Theme.Gameplay.blockHueBrightness,
            alpha: 1
        )
    }
}
