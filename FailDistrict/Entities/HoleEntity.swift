//
//  HoleEntity.swift
//  FailDistrict
//
//  Created by Prayogo kosasih. W on 19/05/26.
//
import SpriteKit
import GameplayKit

class HoleEntity: GKEntity {
    let spriteNode: SKSpriteNode
    
    init(node: SKSpriteNode, scene: GameScene, type: String) {
        self.spriteNode = node
        super.init()
        
        // 1. Set up Physics safely
        if spriteNode.physicsBody == nil {
            spriteNode.physicsBody = SKPhysicsBody(rectangleOf: spriteNode.size)
            spriteNode.physicsBody?.isDynamic = false
        }
        spriteNode.physicsBody?.categoryBitMask = PhysicsCategory.manhole
        spriteNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        spriteNode.physicsBody?.contactTestBitMask = PhysicsCategory.player
        
        // 2. Attach the correct logic component based on the node's name
        if type == "manhole" {
            addComponent(HoleComponent(node: spriteNode, scene: scene))
        } else if type == "movehole" {
            addComponent(MovingHoleComponent(node: spriteNode, scene: scene))
        } else if type == "chasehole" {
            addComponent(ChaseHoleComponent(node: spriteNode, scene: scene))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
