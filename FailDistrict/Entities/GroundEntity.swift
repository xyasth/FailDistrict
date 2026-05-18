
import SpriteKit
import GameplayKit

class GroundEntity: GKEntity {
    var spriteNode: SKSpriteNode
    
    init(size: CGSize, position: CGPoint) {
        spriteNode = SKSpriteNode(color: NSColor.green.withAlphaComponent(0.4), size: size)
        spriteNode.position = position
        
        spriteNode.physicsBody = SKPhysicsBody(rectangleOf: size)
        spriteNode.physicsBody?.isDynamic = false
        spriteNode.physicsBody?.categoryBitMask = PhysicsCategory.ground
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
