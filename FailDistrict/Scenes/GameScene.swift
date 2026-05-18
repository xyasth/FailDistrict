import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var playerEntity: PlayerEntity!
    var groundEntities: [GroundEntity] = []
    
    var cameraNode: SKCameraNode!
    var cameraController: CameraController!
    
    // Referensi untuk mendapatkan ukuran batas kamera
    var mapSize: CGSize = CGSize(width: 1280, height: 800)
    
    lazy var controlSystem: GKComponentSystem<PlayerControlComponent> = {
        return GKComponentSystem(componentClass: PlayerControlComponent.self)
    }()
    
    var lastUpdateTime: TimeInterval = 0
    
    // ECS: Tree obstacle entity
    private var treeObstacleEntity: TreeObstacleEntity?
    
    // Guard state supaya player mati hanya sekali
    private var isPlayerDead = false
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -15.0)
        backgroundColor = .black
        
        parseLevelFromSKS()
        setupPlayer()
        setupTreeObstacleEntity()
        setupCamera()
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
    }
    
    private func setupTreeObstacleEntity() {
        guard let treeNode = childNode(withName: "//tree") as? SKSpriteNode else { return }
        let triggerNode = childNode(withName: "//treeTrigger") as? SKSpriteNode
        
        treeObstacleEntity = TreeObstacleEntity(
            scene: self,
            treeNode: treeNode,
            triggerNode: triggerNode
        )
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
    
    override func keyDown(with event: NSEvent) {
        // R untuk restart setelah mati
        if isPlayerDead && event.charactersIgnoringModifiers?.lowercased() == "r" {
            restartScene()
            return
        }
        
        if let control = playerEntity.component(ofType: PlayerControlComponent.self) {
            control.handleKeyDown(event.keyCode)
        }
    }
    
    override func keyUp(with event: NSEvent) {
        if let control = playerEntity.component(ofType: PlayerControlComponent.self) {
            control.handleKeyUp(event.keyCode)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Saat mati, hentikan kontrol supaya input tidak diproses lagi
        if !isPlayerDead {
            checkPlayerGroundedState()
            controlSystem.update(deltaTime: dt)
        }
    }
    
    override func didSimulatePhysics() {
        cameraController?.update()
    }
    
    private func checkPlayerGroundedState() {
        guard let body = playerEntity.spriteNode.physicsBody else { return }
        
        if let control = playerEntity.component(ofType: PlayerControlComponent.self) {
            for contactedBody in body.allContactedBodies() {
                if contactedBody.categoryBitMask == PhysicsCategory.ground,
                   let groundNode = contactedBody.node {
                    if playerEntity.spriteNode.position.y > groundNode.position.y + (groundNode.frame.height / 2) * 0.8 {
                        control.isGrounded = true
                        break
                    }
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        
        // Player masuk trigger tree => delegasi ke ECS component
        if (maskA == PhysicsCategory.player && maskB == PhysicsCategory.treeTrigger) ||
            (maskA == PhysicsCategory.treeTrigger && maskB == PhysicsCategory.player) {
            treeObstacleEntity?.handlePlayerEnteredTrigger()
            return
        }
        
        // Player kena tree => mati hanya saat tree masih hazard
        if (maskA == PhysicsCategory.player && maskB == PhysicsCategory.tree) ||
            (maskA == PhysicsCategory.tree && maskB == PhysicsCategory.player) {
            if treeObstacleEntity?.shouldKillPlayerOnTreeContact() == true {
                killPlayer()
            }
        }
    }
    
    private func killPlayer() {
        guard !isPlayerDead else { return }
        isPlayerDead = true
        
        if let control = playerEntity.component(ofType: PlayerControlComponent.self) {
            control.isMovingLeft = false
            control.isMovingRight = false
            control.currentJumpBuffer = 0
            control.currentCoyoteTime = 0
            control.isGrounded = false
        }
        
        // Supaya tidak menabrak banyak hal setelah mati
        playerEntity.spriteNode.physicsBody?.velocity = .zero
        playerEntity.spriteNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        playerEntity.spriteNode.physicsBody?.contactTestBitMask = PhysicsCategory.none
        
        // Fail animation sederhana
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
