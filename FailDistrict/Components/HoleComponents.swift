//
//  HoleComponents.swift
//  FailDistrict
//
//  Created by Prayogo kosasih. W on 18/05/26.
//

import SpriteKit
import GameplayKit

// MARK: - 1. Standard Hole
class HoleComponent: GKComponent, Contactable {
    let node: SKSpriteNode
    weak var scene: GameScene?
    var isTriggered = false
    
    init(node: SKSpriteNode, scene: GameScene) {
        self.node = node
        self.scene = scene
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func didBeginContact(with other: GKEntity?, contact: SKPhysicsContact) {}
    func didEndContact(with other: GKEntity?, contact: SKPhysicsContact) {}
    
    override func update(deltaTime seconds: TimeInterval) {
        guard !isTriggered else { return }
        guard let player = scene?.playerEntity?.spriteNode else { return }
        
        // Horizontal check
        let safeMargin = min(45.0, node.size.width * 0.2)
        let holeLeftEdge  = node.position.x - (node.size.width  / 2) + safeMargin
        let holeRightEdge = node.position.x + (node.size.width  / 2) - safeMargin
        
        guard player.position.x > holeLeftEdge,
              player.position.x < holeRightEdge else { return }
        
        // Use the player's bottom edge, not their center
        let playerBottom = player.position.y - (player.size.height / 2)
        let holeTop = node.position.y + (node.size.height / 2)
        
        // Player feet must be at or below the hole surface
        guard playerBottom <= holeTop + 4 else { return }
        
        // If the player is moving upward, they jumped over — let them pass
        let dy = player.physicsBody?.velocity.dy ?? 0
        guard dy <= 0 else { return }
        
        triggerFall(for: player)
    }
    
    fileprivate func triggerFall(for playerNode: SKSpriteNode) {
        isTriggered = true
        
        // Remove ground collision and pull down
        playerNode.physicsBody?.collisionBitMask &= ~PhysicsCategory.ground
        playerNode.physicsBody?.velocity.dy = -400
        playerNode.physicsBody?.velocity.dx = 0
        playerNode.zPosition = 0
        
        let wait = SKAction.wait(forDuration: 0.2)
        let freeze = SKAction.run {
            playerNode.physicsBody?.isDynamic = false
            playerNode.physicsBody?.velocity = .zero
        }
        let killPlayer = SKAction.run { [weak self] in
            self?.scene?.triggerHoleDeath() // Calls FailDistrict's Game Over
        }
        
        playerNode.run(SKAction.sequence([wait, freeze, SKAction.fadeOut(withDuration: 0.1), killPlayer]))
    }
}

// MARK: - 2. Moving Hole
class MovingHoleComponent: HoleComponent {
    var originalX: CGFloat = 0
    let maxSlideDistance: CGFloat = 200.0
    weak var frontVisualNode: SKNode?
    
    override init(node: SKSpriteNode, scene: GameScene) {
        super.init(node: node, scene: scene)
        self.originalX = node.position.x
        
        for child in scene.children where child.name == "MHole" {
            if abs(child.position.x - node.position.x) < 5 && abs(child.position.y - node.position.y) < 5 {
                self.frontVisualNode = child
                break
            }
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        guard !isTriggered else { return }
        
        if let player = scene?.playerEntity?.spriteNode, let velocity = player.physicsBody?.velocity {
            let distanceX = player.position.x - node.position.x
            let distanceY = player.position.y - node.position.y
            
            if distanceY > 40 && (distanceX > -300 && distanceX < 0) && velocity.dx > 0 {
                let predictedX = player.position.x + (velocity.dx * 0.3)
                let step = 450.0 * CGFloat(seconds)
                
                if node.position.x < predictedX && node.position.x < (originalX + maxSlideDistance) {
                    node.position.x += step
                    frontVisualNode?.position.x += step
                }
            }
        }
    }
}

// MARK: - 3. Chasing Hole
class ChaseHoleComponent: HoleComponent {
    var originalX: CGFloat = 0
    let aggroRadius: CGFloat = 600.0
    weak var frontVisualNode: SKNode?
    
    override init(node: SKSpriteNode, scene: GameScene) {
        super.init(node: node, scene: scene)
        self.originalX = node.position.x
        
        for child in scene.children where child.name == "CHole" {
            if abs(child.position.x - node.position.x) < 5 && abs(child.position.y - node.position.y) < 5 {
                self.frontVisualNode = child
                break
            }
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        guard !isTriggered, let player = scene?.playerEntity?.spriteNode else { return }
        
        let distanceToOriginal = abs(player.position.x - originalX)
        if distanceToOriginal <= aggroRadius {
            let direction: CGFloat = player.position.x > node.position.x ? 1.0 : -1.0
            let step = 180 * CGFloat(seconds) * direction
            let newX = node.position.x + step
            
            if abs(newX - originalX) <= aggroRadius {
                node.position.x = newX
                frontVisualNode?.position.x = newX
            }
        }
        /*
         <<<Func to make the hole go back to original position>>>
         else {
         let distanceToHome = originalX - node.position.x
         if abs(distanceToHome) > 1.0 {
         let direction: CGFloat = distanceToHome > 0 ? 1.0 : -1.0
         let step = 80.0 * CGFloat(seconds) * direction
         node.position.x += step
         frontVisualNode?.position.x += step
         }
         }
         */
    }
}
