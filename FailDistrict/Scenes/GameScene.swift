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
    
    // Tree obstacle nodes from GameScene.sks
    private var treePivotNode: SKNode?
    private var treeNode: SKSpriteNode?
    private var treeTriggerNode: SKSpriteNode?
    
    // Guard state supaya trigger hanya sekali
    private var hasTreeTriggered = false
    
    // Guard state supaya player mati hanya sekali
    private var isPlayerDead = false
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -15.0)
        backgroundColor = .black
        
        parseLevelFromSKS()
        setupPlayer()
        setupTreeObstacle()
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
    
    private func setupTreeObstacle() {
        // Ambil node tree dan trigger yang sudah kamu pasang di GameScene.sks
        treeNode = childNode(withName: "//tree") as? SKSpriteNode
        treeTriggerNode = childNode(withName: "//treeTrigger") as? SKSpriteNode
        
        guard let treeNode = treeNode else { return }
        
        // Buat pivot node di posisi bawah batang, lalu jadikan tree sebagai child.
        // Rotasi nanti dilakukan di pivot, jadi titik jatuh stabil di akar pohon.
        let originalPosition = treeNode.position
        let originalZPosition = treeNode.zPosition
        
        let pivot = SKNode()
        pivot.name = "treePivot"
        pivot.position = originalPosition
        addChild(pivot)
        
        treeNode.removeFromParent()
        treeNode.zPosition = originalZPosition
        // Pakai anchor tengah supaya physics body texture tetap sejajar stabil.
        treeNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        // Geser sprite ke atas pivot, jadi pivot tetap di pangkal batang.
        treeNode.position = CGPoint(x: 0, y: treeNode.size.height * 0.5)
        pivot.addChild(treeNode)
        treePivotNode = pivot
        
        // Physics body tetap pakai bentuk texture pohon
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
        
        if let trigger = treeTriggerNode {
            // Trigger tidak terlihat dan tidak ikut physics simulation
            // trigger.alpha = 0.001
            trigger.alpha = 0.5
            trigger.physicsBody = SKPhysicsBody(rectangleOf: trigger.size)
            trigger.physicsBody?.isDynamic = false
            trigger.physicsBody?.affectedByGravity = false
            trigger.physicsBody?.categoryBitMask = PhysicsCategory.treeTrigger
            trigger.physicsBody?.collisionBitMask = PhysicsCategory.none
            trigger.physicsBody?.contactTestBitMask = PhysicsCategory.player
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
                if contactedBody.categoryBitMask == PhysicsCategory.ground {
                    if let groundNode = contactedBody.node {
                        if playerEntity.spriteNode.position.y > groundNode.position.y + (groundNode.frame.height / 2) * 0.8 {
                            control.isGrounded = true
                            break
                        }
                    }
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        
        // Player masuk trigger pohon => pohon jatuh (sekali saja)
        if (maskA == PhysicsCategory.player && maskB == PhysicsCategory.treeTrigger) ||
            (maskA == PhysicsCategory.treeTrigger && maskB == PhysicsCategory.player) {
            triggerTreeFallOnce()
            return
        }
        
        // Player kena pohon => mati
        if (maskA == PhysicsCategory.player && maskB == PhysicsCategory.tree) ||
            (maskA == PhysicsCategory.tree && maskB == PhysicsCategory.player) {
            killPlayer()
        }
    }
    
    private func triggerTreeFallOnce() {
        guard !hasTreeTriggered, let treePivotNode = treePivotNode else { return }
        hasTreeTriggered = true
        
        // Rotasi pivot (bukan sprite) supaya pangkal pohon jadi titik putar.
        let fallLeft = SKAction.rotate(toAngle: (.pi / 2), duration: 0.45, shortestUnitArc: true)
        fallLeft.timingMode = .easeIn
        treePivotNode.run(fallLeft)
        
        // Hapus trigger supaya tidak pernah aktif lagi
        treeTriggerNode?.removeFromParent()
        treeTriggerNode = nil
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
