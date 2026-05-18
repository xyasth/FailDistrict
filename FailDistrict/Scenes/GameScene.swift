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
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -15.0)
        backgroundColor = .black
        
        parseLevelFromSKS()
        setupPlayer()
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
        
        checkPlayerGroundedState()
        controlSystem.update(deltaTime: dt)
        
//        cameraController.update()
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
}
