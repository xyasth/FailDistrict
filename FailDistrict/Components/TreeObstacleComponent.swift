import SpriteKit
import GameplayKit

final class TreeObstacleComponent: GKComponent {
    private weak var scene: SKScene?
    private weak var treeNode: SKSpriteNode?
    private weak var triggerNode: SKSpriteNode?

    private var treePivotNode: SKNode?
    private var hasTriggered = false
    private var isPassive = false

    init(scene: SKScene, treeNode: SKSpriteNode, triggerNode: SKSpriteNode?) {
        self.scene = scene
        self.treeNode = treeNode
        self.triggerNode = triggerNode
        super.init()

        setupTreeHierarchyAndPhysics()
        setupTriggerPhysics()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handlePlayerEnteredTrigger() {
        guard !hasTriggered, let treePivotNode else { return }
        hasTriggered = true

        let fall = SKAction.rotate(toAngle: (.pi / 2), duration: 0.45, shortestUnitArc: true)
        fall.timingMode = .easeIn

        let becomePassive = SKAction.run { [weak self] in
            self?.makeTreePassive()
        }

        treePivotNode.run(SKAction.sequence([fall, becomePassive]))
        triggerNode?.removeFromParent()
        triggerNode = nil
    }

    func shouldKillPlayerOnTreeContact() -> Bool {
        return hasTriggered && !isPassive
    }

    func matchesTriggerNode(_ node: SKNode?) -> Bool {
        return node === triggerNode
    }

    func matchesTreeNode(_ node: SKNode?) -> Bool {
        return node === treeNode
    }

    private func setupTreeHierarchyAndPhysics() {
        guard let scene, let treeNode else { return }

        let originalPosition = treeNode.position
        let originalZPosition = treeNode.zPosition

        let pivot = SKNode()
        pivot.name = "treePivot"
        pivot.position = originalPosition
        scene.addChild(pivot)

        treeNode.removeFromParent()
        treeNode.zPosition = originalZPosition
        treeNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        treeNode.position = CGPoint(x: 0, y: treeNode.size.height * 0.5)
        pivot.addChild(treeNode)

        treePivotNode = pivot

        if let texture = treeNode.texture {
            treeNode.physicsBody = SKPhysicsBody(texture: texture, size: treeNode.size)
        } else {
            treeNode.physicsBody = SKPhysicsBody(rectangleOf: treeNode.size)
        }

        treeNode.physicsBody?.isDynamic = false
        treeNode.physicsBody?.affectedByGravity = false
        treeNode.physicsBody?.allowsRotation = false
        treeNode.physicsBody?.categoryBitMask = PhysicsCategory.tree
        treeNode.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.player
        treeNode.physicsBody?.contactTestBitMask = PhysicsCategory.player
        treeNode.physicsBody?.friction = 0.8
        treeNode.physicsBody?.restitution = 0.0
        treeNode.physicsBody?.angularDamping = 0.5
    }

    private func setupTriggerPhysics() {
        guard let triggerNode else { return }

        // alpa set to 0.001 to hide it
        triggerNode.alpha = 0.4
        triggerNode.physicsBody = SKPhysicsBody(rectangleOf: triggerNode.size)
        triggerNode.physicsBody?.isDynamic = false
        triggerNode.physicsBody?.affectedByGravity = false
        triggerNode.physicsBody?.categoryBitMask = PhysicsCategory.treeTrigger
        triggerNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        triggerNode.physicsBody?.contactTestBitMask = PhysicsCategory.player
    }

    private func makeTreePassive() {
        guard let treeBody = treeNode?.physicsBody else { return }

        isPassive = true
        treeBody.categoryBitMask = PhysicsCategory.none
        treeBody.collisionBitMask = PhysicsCategory.none
        treeBody.contactTestBitMask = PhysicsCategory.none
        treeBody.isDynamic = false
        treeBody.affectedByGravity = false
    }
}
