import GameplayKit
import SpriteKit

final class FruitDropEntity: GKEntity {
    init(fruitNode: SKSpriteNode, triggerNode: SKSpriteNode?) {
        super.init()

        let component = FruitDropComponent(
            fruitNode: fruitNode,
            triggerNode: triggerNode
        )
        addComponent(component)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handlePlayerEnteredTrigger() {
        component(ofType: FruitDropComponent.self)?.handlePlayerEnteredTrigger()
    }

    func handleFruitHitGround() {
        component(ofType: FruitDropComponent.self)?.handleFruitHitGround()
    }

    func shouldKillPlayerOnFruitContact() -> Bool {
        component(ofType: FruitDropComponent.self)?.shouldKillPlayerOnFruitContact() ?? false
    }
}
