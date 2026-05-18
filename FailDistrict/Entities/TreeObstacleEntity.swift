import GameplayKit
import SpriteKit

final class TreeObstacleEntity: GKEntity {
    init(scene: SKScene, treeNode: SKSpriteNode, triggerNode: SKSpriteNode?) {
        super.init()

        let component = TreeObstacleComponent(
            scene: scene,
            treeNode: treeNode,
            triggerNode: triggerNode
        )
        addComponent(component)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handlePlayerEnteredTrigger() {
        component(ofType: TreeObstacleComponent.self)?.handlePlayerEnteredTrigger()
    }

    func shouldKillPlayerOnTreeContact() -> Bool {
        component(ofType: TreeObstacleComponent.self)?.shouldKillPlayerOnTreeContact() ?? false
    }

    func matchesTriggerNode(_ node: SKNode?) -> Bool {
        component(ofType: TreeObstacleComponent.self)?.matchesTriggerNode(node) ?? false
    }

    func matchesTreeNode(_ node: SKNode?) -> Bool {
        component(ofType: TreeObstacleComponent.self)?.matchesTreeNode(node) ?? false
    }
}
