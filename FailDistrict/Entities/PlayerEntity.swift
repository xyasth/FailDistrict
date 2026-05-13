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
        // 1. Pembuatan Wujud Visual
        spriteNode = SKSpriteNode(color: .cyan, size: CGSize(width: 40, height: 40))
        spriteNode.position = position
        
        // 2. Setingan Fisika (Tubuh)
        spriteNode.physicsBody = SKPhysicsBody(circleOfRadius: spriteNode.size.width / 2)
        spriteNode.physicsBody?.allowsRotation = false
        spriteNode.physicsBody?.categoryBitMask = PhysicsCategory.player
        spriteNode.physicsBody?.collisionBitMask = PhysicsCategory.ground // Bisa nabrak tanah
        spriteNode.physicsBody?.contactTestBitMask = PhysicsCategory.ground // Melapor kalau nyentuh tanah
        spriteNode.physicsBody?.restitution = 0.0 // Tidak memantul
        spriteNode.physicsBody?.friction = 0.0 // Tidak ada gesekan
        
        super.init()
        
        // 3. Penanaman Otak (Komponen)
        let controlComponent = PlayerControlComponent(node: spriteNode)
        addComponent(controlComponent)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
