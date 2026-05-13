import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var playerEntity: PlayerEntity!
    var groundEntities: [GroundEntity] = []
    
    var cameraNode: SKCameraNode!
    var cameraController: CameraController!
    var mapVisual: SKSpriteNode!
    
    lazy var controlSystem: GKComponentSystem<PlayerControlComponent> = {
        return GKComponentSystem(componentClass: PlayerControlComponent.self)
    }()
    
    var lastUpdateTime: TimeInterval = 0
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -12.0)
        backgroundColor = .white // Luar map warnanya hitam
        
        // Urutan ini sangat penting agar tidak crash
        setupLevel()
        setupPlayer()
        setupCamera()
    }
    
    private func setupLevel() {
        // Pastikan nama file gambar kamu di Assets adalah "bg"
        mapVisual = SKSpriteNode(imageNamed: "bg")
        mapVisual.anchorPoint = CGPoint(x: 0, y: 0) // Pojok kiri bawah jadi titik 0,0
        mapVisual.position = CGPoint(x: 0, y: 0)
        mapVisual.zPosition = -10
        addChild(mapVisual)
        
        // Pijakan utama yang menutupi gambar lantai di background
        let mainGround = GroundEntity(size: CGSize(width: mapVisual.size.width, height: 50), position: CGPoint(x: mapVisual.size.width / 2, y: 100))
        mainGround.spriteNode.zPosition = -5
        groundEntities.append(mainGround)
        addChild(mainGround.spriteNode)
    }
    
    private func setupPlayer() {
        playerEntity = PlayerEntity(position: CGPoint(x: 100, y: 150))
        addChild(playerEntity.spriteNode)
        controlSystem.addComponent(foundIn: playerEntity)
    }
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        
        // --- Setting Zoom Out ---
        cameraNode.setScale(1)
        
        addChild(cameraNode)
        self.camera = cameraNode
        
        cameraController = CameraController(
            cameraNode: cameraNode,
            targetNode: playerEntity.spriteNode,
            viewSize: self.size,
            mapSize: mapVisual.size
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
        
        // Kamera diperbarui paling akhir
        cameraController.update()
    }
    
    private func checkPlayerGroundedState() {
        guard let body = playerEntity.spriteNode.physicsBody else { return }
        
        if let control = playerEntity.component(ofType: PlayerControlComponent.self) {
            for contactedBody in body.allContactedBodies() {
                if contactedBody.categoryBitMask == PhysicsCategory.ground {
                    if let groundNode = contactedBody.node {
                        // Toleransi injak 80% dari tengah kotak
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
