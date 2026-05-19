import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    enum GameState {
        case playing
        case dead
    }
    
    var playerEntity: PlayerEntity!
    private var playerControl: PlayerControlComponent?
    var groundEntities: [GroundEntity] = []
    var holeEntities: [HoleEntity] = []
    
    var cameraNode: SKCameraNode!
    var cameraController: CameraController!
    
    // Referensi untuk mendapatkan ukuran batas kamera
    var mapSize: CGSize = CGSize(width: 1280, height: 800)
    
    lazy var controlSystem: GKComponentSystem<PlayerControlComponent> = {
        return GKComponentSystem(componentClass: PlayerControlComponent.self)
    }()
    
    var lastUpdateTime: TimeInterval = 0
    
    // ECS obstacles (multi instance)
    private var treeObstacleEntities: [TreeObstacleEntity] = []
    private var fruitDropEntities: [FruitDropEntity] = []
    private var monitorDropEntities: [MonitorDropEntity] = []
    
    // State game sederhana
    private var gameState: GameState = .playing
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -15.0)
        backgroundColor = .black
        
        parseLevelFromSKS()
        setupPlayer()
        setupTreeObstacleEntities()
        setupFruitDropEntities()
        setupMonitorDropEntities()
        setupCamera()
        setupHoles()
    }
    
    private func parseLevelFromSKS() {
        if let bgNode = self.childNode(withName: "//mapBackground") as? SKSpriteNode {
            self.mapSize = bgNode.size
        }
        
        for node in self.children {
            if node.name == "ground_placeholder", let spriteNode = node as? SKSpriteNode {
                let size = spriteNode.size
                let position = spriteNode.position
                
                let formalGround = GroundEntity(size: size, position: position)
                formalGround.spriteNode.zPosition = spriteNode.zPosition
                
                groundEntities.append(formalGround)
                addChild(formalGround.spriteNode)
                
                spriteNode.removeFromParent()
            }
        }
    }
    
    private func setupPlayer() {
        var startPosition = CGPoint(x: 100, y: 150)
        
        if let spawnNode = self.childNode(withName: "//player_spawn") {
            startPosition = spawnNode.position
            spawnNode.removeFromParent()
        }
        
        playerEntity = PlayerEntity(position: startPosition)
        addChild(playerEntity.spriteNode)
        controlSystem.addComponent(foundIn: playerEntity)
        playerControl = playerEntity.component(ofType: PlayerControlComponent.self)
    }
    
    private func setupTreeObstacleEntities() {
        treeObstacleEntities.removeAll()
        
        // Multi naming: tree_1 + tree_1_trigger, tree_2 + tree_2_trigger, ...
        let indexedTrees = children.compactMap { node -> SKSpriteNode? in
            guard let sprite = node as? SKSpriteNode, let name = sprite.name else { return nil }
            guard name.hasPrefix("tree_"), !name.hasSuffix("_trigger") else { return nil }
            return sprite
        }
        
        for treeNode in indexedTrees {
            let triggerName = "\(treeNode.name ?? "")_trigger"
            let triggerNode = childNode(withName: "//\(triggerName)") as? SKSpriteNode
            let entity = TreeObstacleEntity(scene: self, treeNode: treeNode, triggerNode: triggerNode)
            treeObstacleEntities.append(entity)
        }
        
        // Legacy fallback: single tree + treeTrigger
        if treeObstacleEntities.isEmpty,
           let treeNode = childNode(withName: "//tree") as? SKSpriteNode {
            let triggerNode = childNode(withName: "//treeTrigger") as? SKSpriteNode
            let entity = TreeObstacleEntity(scene: self, treeNode: treeNode, triggerNode: triggerNode)
            treeObstacleEntities.append(entity)
        }
    }
    
    private func setupFruitDropEntities() {
        fruitDropEntities.removeAll()
        
        // Multi naming: fruit_1 + fruit_1_trigger, fruit_2 + fruit_2_trigger, ...
        let indexedFruits = children.compactMap { node -> SKSpriteNode? in
            guard let sprite = node as? SKSpriteNode, let name = sprite.name else { return nil }
            guard name.hasPrefix("fruit_"), !name.hasSuffix("_trigger") else { return nil }
            return sprite
        }
        
        for fruitNode in indexedFruits {
            let triggerName = "\(fruitNode.name ?? "")_trigger"
            let triggerNode = childNode(withName: "//\(triggerName)") as? SKSpriteNode
            let entity = FruitDropEntity(fruitNode: fruitNode, triggerNode: triggerNode)
            fruitDropEntities.append(entity)
        }
        
        // Legacy fallback: single fruit + fruitTrigger
        if fruitDropEntities.isEmpty,
           let fruitNode = childNode(withName: "//fruit") as? SKSpriteNode {
            let triggerNode = childNode(withName: "//fruitTrigger") as? SKSpriteNode
            let entity = FruitDropEntity(fruitNode: fruitNode, triggerNode: triggerNode)
            fruitDropEntities.append(entity)
        }
    }

    private func setupMonitorDropEntities() {
        monitorDropEntities.removeAll()

        // Multi naming: building_1_monitorTrigger + building_1_monitorSpawn, ...
        let monitorTriggerNodes = children.compactMap { node -> SKSpriteNode? in
            guard let sprite = node as? SKSpriteNode, let name = sprite.name else { return nil }
            guard name.hasSuffix("_monitorTrigger") else { return nil }
            return sprite
        }

        for triggerNode in monitorTriggerNodes {
            let baseName = triggerNode.name?.replacingOccurrences(of: "_monitorTrigger", with: "") ?? ""
            let spawnNode = childNode(withName: "//\(baseName)_monitorSpawn")
            let entity = MonitorDropEntity(scene: self, triggerNode: triggerNode, spawnPointNode: spawnNode)
            monitorDropEntities.append(entity)
        }

        // Legacy fallback: single monitorTrigger + monitorSpawnPoint
        if monitorDropEntities.isEmpty,
           let triggerNode = childNode(withName: "//monitorTrigger") as? SKSpriteNode {
            let spawnNode = childNode(withName: "//monitorSpawnPoint")
            let entity = MonitorDropEntity(scene: self, triggerNode: triggerNode, spawnPointNode: spawnNode)
            monitorDropEntities.append(entity)
        }
    }
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        cameraNode.setScale(1.0)
        
        addChild(cameraNode)
        self.camera = cameraNode
        
        cameraController = CameraController(
            cameraNode: cameraNode,
            targetNode: playerEntity.spriteNode,
            viewSize: self.size,
            mapSize: self.mapSize
        )
        
        cameraNode.position.x = playerEntity.spriteNode.position.x
        cameraNode.position.y = self.size.height / 2
    }
    
    private func setupHoles() {
        holeEntities.removeAll()
        
        for node in children {
            guard let sprite = node as? SKSpriteNode, let name = sprite.name else { continue }
            
            if name == "manhole" || name == "movehole" || name == "chasehole" {
                let entity = HoleEntity(node: sprite, scene: self, type: name)
                holeEntities.append(entity)
            }
        }
    }
    
    override func keyDown(with event: NSEvent) {
        // R untuk restart setelah mati
        if gameState == .dead && event.charactersIgnoringModifiers?.lowercased() == "r" {
            restartScene()
            return
        }
        
        playerControl?.handleKeyDown(event.keyCode)
    }
    
    override func keyUp(with event: NSEvent) {
        playerControl?.handleKeyUp(event.keyCode)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        if gameState == .playing {
            checkPlayerGroundedState()
            controlSystem.update(deltaTime: dt)
            
            for entity in holeEntities {
                entity.update(deltaTime: dt)
            }
        }
    }
    
    override func didSimulatePhysics() {
        cameraController?.update()
    }
    
    private func checkPlayerGroundedState() {
        guard
            let body = playerEntity.spriteNode.physicsBody,
            let control = playerControl
        else { return }
        
        for contactedBody in body.allContactedBodies() {
            if contactedBody.categoryBitMask == PhysicsCategory.ground,
               let groundNode = contactedBody.node,
               playerEntity.spriteNode.position.y > groundNode.position.y + (groundNode.frame.height / 2) * 0.8 {
                control.isGrounded = true
                break
            }
        }
    }
    
    private func hasPair(_ a: UInt32, _ b: UInt32, _ x: UInt32, _ y: UInt32) -> Bool {
        return (a == x && b == y) || (a == y && b == x)
    }
    
    private func handleTreeTriggerContact(_ maskA: UInt32, _ maskB: UInt32, nodeA: SKNode?, nodeB: SKNode?) -> Bool {
        guard hasPair(maskA, maskB, PhysicsCategory.player, PhysicsCategory.treeTrigger) else { return false }
        
        for entity in treeObstacleEntities where entity.matchesTriggerNode(nodeA) || entity.matchesTriggerNode(nodeB) {
            entity.handlePlayerEnteredTrigger()
            return true
        }
        return false
    }
    
    private func handleFruitTriggerContact(_ maskA: UInt32, _ maskB: UInt32, nodeA: SKNode?, nodeB: SKNode?) -> Bool {
        guard hasPair(maskA, maskB, PhysicsCategory.player, PhysicsCategory.fruitTrigger) else { return false }
        
        for entity in fruitDropEntities where entity.matchesTriggerNode(nodeA) || entity.matchesTriggerNode(nodeB) {
            entity.handlePlayerEnteredTrigger()
            return true
        }
        return false
    }

    private func handleMonitorTriggerContact(_ maskA: UInt32, _ maskB: UInt32, nodeA: SKNode?, nodeB: SKNode?) -> Bool {
        guard hasPair(maskA, maskB, PhysicsCategory.player, PhysicsCategory.monitorTrigger) else { return false }

        for entity in monitorDropEntities where entity.matchesTriggerNode(nodeA) || entity.matchesTriggerNode(nodeB) {
            entity.handlePlayerEnteredTrigger()
            return true
        }
        return false
    }
    
    private func handlePlayerHazardContact(_ maskA: UInt32, _ maskB: UInt32, nodeA: SKNode?, nodeB: SKNode?) -> Bool {
        if hasPair(maskA, maskB, PhysicsCategory.player, PhysicsCategory.tree) {
            for entity in treeObstacleEntities where entity.matchesTreeNode(nodeA) || entity.matchesTreeNode(nodeB) {
                if entity.shouldKillPlayerOnTreeContact() {
                    killPlayer()
                    return true
                }
            }
        }
        
        if hasPair(maskA, maskB, PhysicsCategory.player, PhysicsCategory.fruit) {
            for entity in fruitDropEntities where entity.matchesFruitNode(nodeA) || entity.matchesFruitNode(nodeB) {
                if entity.shouldKillPlayerOnFruitContact() {
                    killPlayer()
                    return true
                }
            }
        }

        if hasPair(maskA, maskB, PhysicsCategory.player, PhysicsCategory.monitor) {
            for entity in monitorDropEntities where entity.matchesMonitorNode(nodeA) || entity.matchesMonitorNode(nodeB) {
                if entity.shouldKillPlayerOnMonitorContact() {
                    killPlayer()
                    return true
                }
            }
        }
        
        return false
    }
    
    private func handleFruitGroundContact(_ maskA: UInt32, _ maskB: UInt32, nodeA: SKNode?, nodeB: SKNode?) -> Bool {
        guard hasPair(maskA, maskB, PhysicsCategory.fruit, PhysicsCategory.ground) else { return false }
        
        for entity in fruitDropEntities where entity.matchesFruitNode(nodeA) || entity.matchesFruitNode(nodeB) {
            entity.handleFruitHitGround()
            return true
        }
        return false
    }

    private func handleMonitorGroundContact(_ maskA: UInt32, _ maskB: UInt32, nodeA: SKNode?, nodeB: SKNode?) -> Bool {
        guard hasPair(maskA, maskB, PhysicsCategory.monitor, PhysicsCategory.ground) else { return false }

        for entity in monitorDropEntities where entity.matchesMonitorNode(nodeA) || entity.matchesMonitorNode(nodeB) {
            entity.handleMonitorHitGround()
            return true
        }
        return false
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        
        guard gameState == .playing else { return }
        
        if hasPair(maskA, maskB, PhysicsCategory.player, PhysicsCategory.manhole) {
            let holeNode = maskA == PhysicsCategory.manhole ? nodeA : nodeB
            let entity = holeEntities.first { $0.spriteNode == holeNode }
            if let comp = entity?.holeComponent {
                comp.didBeginContact(with: playerEntity, contact: contact)
            }
            return
        }
        
        if handleTreeTriggerContact(maskA, maskB, nodeA: nodeA, nodeB: nodeB) { return }
        if handleFruitTriggerContact(maskA, maskB, nodeA: nodeA, nodeB: nodeB) { return }
        if handleMonitorTriggerContact(maskA, maskB, nodeA: nodeA, nodeB: nodeB) { return }
        if handlePlayerHazardContact(maskA, maskB, nodeA: nodeA, nodeB: nodeB) { return }
        if handleFruitGroundContact(maskA, maskB, nodeA: nodeA, nodeB: nodeB) { return }
        _ = handleMonitorGroundContact(maskA, maskB, nodeA: nodeA, nodeB: nodeB)
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        
        if hasPair(maskA, maskB, PhysicsCategory.player, PhysicsCategory.manhole) {
            let holeNode = maskA == PhysicsCategory.manhole ? nodeA : nodeB
            let entity = holeEntities.first { $0.spriteNode == holeNode }
            if let comp = entity?.holeComponent {
                comp.didEndContact(with: playerEntity, contact: contact)
            }
        }
    }
    
    func triggerHoleDeath() {
        guard gameState == .playing else { return }
        gameState = .dead
        
        if let control = playerControl {
            control.isMovingLeft = false
            control.isMovingRight = false
            control.isGrounded = false
        }
        
        // Stop their physics entirely (no rotation since they fell)
        playerEntity.spriteNode.physicsBody?.velocity = .zero
        playerEntity.spriteNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        showRestartPrompt()
    }
    
    private func killPlayer() {
        guard gameState == .playing else { return }
        gameState = .dead
        
        if let control = playerControl {
            control.isMovingLeft = false
            control.isMovingRight = false
            control.currentJumpBuffer = 0
            control.currentCoyoteTime = 0
            control.isGrounded = false
        }
        
        playerEntity.spriteNode.physicsBody?.velocity = .zero
        playerEntity.spriteNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        playerEntity.spriteNode.physicsBody?.contactTestBitMask = PhysicsCategory.none
        
        let fallAction = SKAction.group([
            SKAction.rotate(byAngle: .pi * 0.5, duration: 0.2),
            SKAction.fadeAlpha(to: 0.4, duration: 0.2)
        ])
        playerEntity.spriteNode.run(fallAction)
        
        showRestartPrompt()
    }
    
    private func showRestartPrompt() {
        guard let cameraNode = cameraNode else { return }
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = "restartLabel"
        label.text = "You Died - Press R to Restart"
        label.fontSize = 36
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 120)
        label.zPosition = 999
        
        cameraNode.addChild(label)
    }
    
    private func restartScene() {
        guard let view = self.view else { return }
        if let scene = GameScene(fileNamed: "GameScene") {
            scene.scaleMode = self.scaleMode
            view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.25))
        }
    }
}
