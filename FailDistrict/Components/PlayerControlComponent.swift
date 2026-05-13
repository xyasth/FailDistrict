import SpriteKit
import GameplayKit

class PlayerControlComponent: GKComponent {
    // Wujud fisik yang akan dikendalikan oleh otak ini
    let node: SKSpriteNode
    
    // Setingan Movement (Rage-bait style: Responsif & Cepat)
    let moveSpeed: CGFloat = 350.0
    let jumpVelocity: CGFloat = 650.0
    
    // Status Input
    var isMovingLeft = false
    var isMovingRight = false
    
    // Timer Fair Play
    var jumpBufferTime: TimeInterval = 0.15
    var currentJumpBuffer: TimeInterval = 0
    
    var coyoteTime: TimeInterval = 0.15
    var currentCoyoteTime: TimeInterval = 0
    
    var isGrounded = false
    
    init(node: SKSpriteNode) {
        self.node = node
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Menerima sinyal keyboard dari GameScene
    func handleKeyDown(_ keyCode: UInt16) {
        switch keyCode {
        case 0, 123: isMovingLeft = true // A atau Kiri
        case 2, 124: isMovingRight = true // D atau Kanan
        case 49, 13, 126: currentJumpBuffer = jumpBufferTime // Spasi, W, Atas
        default: break
        }
    }
    
    func handleKeyUp(_ keyCode: UInt16) {
        switch keyCode {
        case 0, 123: isMovingLeft = false
        case 2, 124: isMovingRight = false
        case 49, 13, 126:
            // Variable jump: Potong kecepatan jika tombol dilepas
            if let dy = node.physicsBody?.velocity.dy, dy > 0 {
                node.physicsBody?.velocity.dy = dy * 0.5
            }
        default: break
        }
    }
    
    // Dipanggil 60 kali per detik oleh Mandor di GameScene
    override func update(deltaTime seconds: TimeInterval) {
        // 1. Update Timer Coyote & Buffer
        if isGrounded {
            currentCoyoteTime = coyoteTime
        } else {
            currentCoyoteTime -= seconds
        }
        
        currentJumpBuffer -= seconds
        
        // 2. Kalkulasi Kecepatan Horizontal (Direct Velocity)
        var targetVelocityX: CGFloat = 0
        if isMovingLeft { targetVelocityX = -moveSpeed }
        if isMovingRight { targetVelocityX = moveSpeed }
        
        node.physicsBody?.velocity.dx = targetVelocityX
        
        // 3. Eksekusi Loncat
        if currentJumpBuffer > 0 && currentCoyoteTime > 0 {
            executeJump()
        }
        
        // Selalu reset grounded. Nanti dicek ulang oleh sensor tabrakan di GameScene.
        isGrounded = false
    }
    
    private func executeJump() {
        node.physicsBody?.velocity.dy = jumpVelocity
        currentJumpBuffer = 0
        currentCoyoteTime = 0
    }
}
