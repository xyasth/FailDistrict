//
//  PlayerEntity.swift
//  FailDistrict
//
//  Created by Hansel Meinhard on 13/05/26.
//

import SpriteKit
import GameplayKit

class PlayerEntity: GKEntity {
    var spriteNode: SKSpriteNode
    
    init(position: CGPoint) {
        // Pembuatan Visual Player
        spriteNode = SKSpriteNode(imageNamed: "PlayerIdle")
        spriteNode.size = CGSize(width: 100, height: 100)
        
        spriteNode.zPosition = 10
        
//        spriteNode = SKSpriteNode(color: .cyan, size: CGSize(width: 60, height: 60))
        spriteNode.position = position
        
        // Setingan Physics
//        spriteNode.physicsBody = SKPhysicsBody(circleOfRadius: spriteNode.size.width / 2)
        if let texture = spriteNode.texture {
            spriteNode.physicsBody = SKPhysicsBody(texture: texture, size: spriteNode.size)
        } else {
            let texture = SKTexture(imageNamed: "PlayerIdle")
            spriteNode.physicsBody = SKPhysicsBody(texture: texture, size: spriteNode.size)
        }
//        
        spriteNode.physicsBody?.allowsRotation = false
        spriteNode.physicsBody?.categoryBitMask = PhysicsCategory.player
        spriteNode.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.tree | PhysicsCategory.fruit // Bisa nabrak tanah, pohon, buah
        spriteNode.physicsBody?.contactTestBitMask = PhysicsCategory.ground | PhysicsCategory.treeTrigger | PhysicsCategory.tree | PhysicsCategory.fruitTrigger | PhysicsCategory.fruit // Melapor sentuhan penting
        spriteNode.physicsBody?.restitution = 0.0 // Tidak memantul
        spriteNode.physicsBody?.friction = 0.0 // Tidak ada gesekand
        
        super.init()
        
        let controlComponent = PlayerControlComponent(node: spriteNode)
        addComponent(controlComponent)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
