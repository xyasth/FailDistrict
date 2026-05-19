import GameplayKit
import SpriteKit

final class MonitorDropEntity: GKEntity {
    init(scene: SKScene, triggerNode: SKSpriteNode?, spawnPointNode: SKNode?) {
        super.init()

        let component = MonitorDropComponent(
            scene: scene,
            triggerNode: triggerNode,
            spawnPointNode: spawnPointNode
        )
        addComponent(component)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handlePlayerEnteredTrigger() {
        component(ofType: MonitorDropComponent.self)?.handlePlayerEnteredTrigger()
    }

    func handleMonitorHitGround() {
        component(ofType: MonitorDropComponent.self)?.handleMonitorHitGround()
    }

    func shouldKillPlayerOnMonitorContact() -> Bool {
        component(ofType: MonitorDropComponent.self)?.shouldKillPlayerOnMonitorContact() ?? false
    }

    func matchesTriggerNode(_ node: SKNode?) -> Bool {
        component(ofType: MonitorDropComponent.self)?.matchesTriggerNode(node) ?? false
    }

    func matchesMonitorNode(_ node: SKNode?) -> Bool {
        component(ofType: MonitorDropComponent.self)?.matchesMonitorNode(node) ?? false
    }
}
