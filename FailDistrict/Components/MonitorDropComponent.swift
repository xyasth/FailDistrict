import SpriteKit
import GameplayKit

final class MonitorDropComponent: GKComponent {
    private weak var scene: SKScene?
    private weak var triggerNode: SKSpriteNode?
    private weak var spawnPointNode: SKNode?
    private weak var monitorNode: SKSpriteNode?
    private let monitorSize = CGSize(width: 70, height: 55)

    private var hasTriggered = false
    private var hasLanded = false

    init(scene: SKScene, triggerNode: SKSpriteNode?, spawnPointNode: SKNode?) {
        self.scene = scene
        self.triggerNode = triggerNode
        self.spawnPointNode = spawnPointNode
        super.init()

        setupTriggerPhysics()
        setupMonitorTemplate()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handlePlayerEnteredTrigger() {
        guard !hasTriggered else { return }
        hasTriggered = true

        activateAndThrowMonitor()
        triggerNode?.removeFromParent()
        triggerNode = nil
    }

    func handleMonitorHitGround() {
        guard hasTriggered, !hasLanded, let monitorNode = monitorNode else { return }
        hasLanded = true

        // Monitor sudah tidak berbahaya setelah mendarat.
        monitorNode.physicsBody?.contactTestBitMask = PhysicsCategory.none
        monitorNode.physicsBody?.collisionBitMask = PhysicsCategory.ground
        monitorNode.physicsBody?.angularVelocity = 0

        let wait = SKAction.wait(forDuration: 2.0)
        let remove = SKAction.removeFromParent()
        monitorNode.run(.sequence([wait, remove]))
    }

    func shouldKillPlayerOnMonitorContact() -> Bool {
        return hasTriggered && !hasLanded
    }

    func matchesTriggerNode(_ node: SKNode?) -> Bool {
        return node === triggerNode
    }

    func matchesMonitorNode(_ node: SKNode?) -> Bool {
        return node === monitorNode
    }

    private func setupTriggerPhysics() {
        guard let triggerNode else { return }

        triggerNode.alpha = 0.4
        triggerNode.physicsBody = SKPhysicsBody(rectangleOf: triggerNode.size)
        triggerNode.physicsBody?.isDynamic = false
        triggerNode.physicsBody?.affectedByGravity = false
        triggerNode.physicsBody?.categoryBitMask = PhysicsCategory.monitorTrigger
        triggerNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        triggerNode.physicsBody?.contactTestBitMask = PhysicsCategory.player
    }

    private func setupMonitorTemplate() {
        guard let scene else { return }
        let spawnPosition = spawnPointNode?.position ?? CGPoint(x: 0, y: 0)
        let monitor = SKSpriteNode(imageNamed: "monitor")
        monitor.name = "monitor_runtime"
        monitor.position = spawnPosition
        monitor.zPosition = 12
        monitor.size = monitorSize
        monitor.isHidden = true

        if let texture = monitor.texture {
            monitor.physicsBody = SKPhysicsBody(texture: texture, size: monitor.size)
        } else {
            monitor.physicsBody = SKPhysicsBody(rectangleOf: monitor.size)
        }

        //monitor.physicsBody?.mass = 0.2
        monitor.physicsBody?.isDynamic = false
        monitor.physicsBody?.affectedByGravity = false
        monitor.physicsBody?.allowsRotation = true
        monitor.physicsBody?.categoryBitMask = PhysicsCategory.monitor
        monitor.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.player
        monitor.physicsBody?.contactTestBitMask = PhysicsCategory.ground | PhysicsCategory.player
        monitor.physicsBody?.restitution = 0.05
        monitor.physicsBody?.friction = 0.7
        monitor.physicsBody?.linearDamping = 0.15
        monitor.physicsBody?.angularDamping = 0.2

        scene.addChild(monitor)
        monitorNode = monitor
    }

    private func activateAndThrowMonitor() {
        guard let monitor = monitorNode else { return }
        monitor.isHidden = false
        monitor.physicsBody?.isDynamic = true
        monitor.physicsBody?.affectedByGravity = true
        monitor.physicsBody?.velocity = .zero
        monitor.physicsBody?.angularVelocity = 0

        // dx dorong monitor ke depan. dy dorong naik sedikit.
        // Gravity lalu tarik ke bawah -> lintasan parabola.
        monitor.physicsBody?.applyImpulse(CGVector(dx: -18.0, dy: 12.0))
        monitor.physicsBody?.applyAngularImpulse(0.0035)
    }
}
