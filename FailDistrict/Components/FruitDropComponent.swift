import SpriteKit
import GameplayKit

final class FruitDropComponent: GKComponent {
    private weak var fruitNode: SKSpriteNode?
    private weak var triggerNode: SKSpriteNode?

    private var hasTriggered = false
    private var hasLanded = false

    init(fruitNode: SKSpriteNode, triggerNode: SKSpriteNode?) {
        self.fruitNode = fruitNode
        self.triggerNode = triggerNode
        super.init()

        setupFruitPhysics()
        setupTriggerPhysics()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handlePlayerEnteredTrigger() {
        guard !hasTriggered, let fruitBody = fruitNode?.physicsBody else { return }
        hasTriggered = true

        fruitBody.isDynamic = true
        fruitBody.affectedByGravity = true

        triggerNode?.removeFromParent()
        triggerNode = nil
    }

    func handleFruitHitGround() {
        guard hasTriggered, !hasLanded, let fruitNode = fruitNode else { return }
        hasLanded = true

        // Setelah menyentuh tanah, buah hilang beberapa detik kemudian.
        let wait = SKAction.wait(forDuration: 2.0)
        let remove = SKAction.removeFromParent()
        fruitNode.run(.sequence([wait, remove]))

        // Supaya tidak terus kirim contact berulang.
        fruitNode.physicsBody?.contactTestBitMask = PhysicsCategory.none
    }

    func shouldKillPlayerOnFruitContact() -> Bool {
        return hasTriggered && !hasLanded
    }

    private func setupFruitPhysics() {
        guard let fruitNode = fruitNode else { return }

        if let texture = fruitNode.texture {
            fruitNode.physicsBody = SKPhysicsBody(texture: texture, size: fruitNode.size)
        } else {
            fruitNode.physicsBody = SKPhysicsBody(circleOfRadius: fruitNode.size.width * 0.5)
        }

        fruitNode.physicsBody?.isDynamic = false
        fruitNode.physicsBody?.affectedByGravity = false
        fruitNode.physicsBody?.allowsRotation = true
        fruitNode.physicsBody?.categoryBitMask = PhysicsCategory.fruit
        fruitNode.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.player
        fruitNode.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.ground
        fruitNode.physicsBody?.restitution = 0.0
        fruitNode.physicsBody?.friction = 0.6
        fruitNode.physicsBody?.linearDamping = 0.1
        fruitNode.physicsBody?.angularDamping = 0.3
    }

    private func setupTriggerPhysics() {
        guard let triggerNode = triggerNode else { return }

        triggerNode.alpha = 0.001
        triggerNode.physicsBody = SKPhysicsBody(rectangleOf: triggerNode.size)
        triggerNode.physicsBody?.isDynamic = false
        triggerNode.physicsBody?.affectedByGravity = false
        triggerNode.physicsBody?.categoryBitMask = PhysicsCategory.fruitTrigger
        triggerNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        triggerNode.physicsBody?.contactTestBitMask = PhysicsCategory.player
    }
}
