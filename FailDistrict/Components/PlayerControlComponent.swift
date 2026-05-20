import SpriteKit
import GameplayKit

class PlayerControlComponent: GKComponent {
    let node: SKSpriteNode
    
    // Setingan Movement
    let moveSpeed: CGFloat = 450.0
    let jumpVelocity: CGFloat = 850.0
    
    // Status Input
    var isMovingLeft = false
    var isMovingRight = false
    
    // Timer Fair Play
    var jumpBufferTime: TimeInterval = 0.15
    var currentJumpBuffer: TimeInterval = 0
    
    var coyoteTime: TimeInterval = 0.15
    var currentCoyoteTime: TimeInterval = 0
    
    var isGrounded = false
    
    // NEW: Variabel Animasi
    var walkFrames: [SKTexture] = []
    var idleFrame: SKTexture!
    var isAnimating = false
    
    init(node: SKSpriteNode) {
        self.node = node
        
        // Setup Tekstur Animasi
        // Pastikan nama gambar sesuai dengan yang ada di Assets.xcassets
        self.idleFrame = SKTexture(imageNamed: "PlayerIdle")
        self.walkFrames = [
            SKTexture(imageNamed: "PlayerWalk1"),
            SKTexture(imageNamed: "PlayerWalk2")
        ]
        
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
    
    // Dipanggil 60 kali per detik
    override func update(deltaTime seconds: TimeInterval) {
        // Update Timer Coyote & Buffer
        if isGrounded {
            currentCoyoteTime = coyoteTime
        } else {
            currentCoyoteTime -= seconds
        }
        
        currentJumpBuffer -= seconds
        
        var directionModifier: CGFloat = 0
        if isMovingLeft {
            directionModifier -= 1
            // Hadap Kiri
            node.xScale = -abs(node.xScale)
        }
        if isMovingRight {
            directionModifier += 1
            // Hadap Kanan
            node.xScale = abs(node.xScale)
        }
        
        let targetVelocityX = moveSpeed * directionModifier
        
        node.physicsBody?.velocity.dx = targetVelocityX
        
        // Logika Animasi
        // Hanya putar animasi jalan jika ada tombol yang ditekan (direction != 0) DAN sedang menginjak tanah
        if directionModifier != 0 && isGrounded {
            if !isAnimating {
                startWalkingAnimation()
            }
        } else {
            // Jika diam atau sedang melompat, hentikan animasi jalan
            if isAnimating {
                stopWalkingAnimation()
            }
        }
        
        // Eksekusi Jump
        if currentJumpBuffer > 0 && currentCoyoteTime > 0 {
            executeJump()
        }
        
        isGrounded = false
    }
    
    private func executeJump() {
        node.physicsBody?.velocity.dy = jumpVelocity
        currentJumpBuffer = 0
        currentCoyoteTime = 0
    }
    
    // NEW: Helper Functions Animasi
    private func startWalkingAnimation() {
        isAnimating = true
        // Kecepatan animasi (0.15 detik per frame)
        let walkAction = SKAction.animate(with: walkFrames, timePerFrame: 0.15)
        let repeatWalk = SKAction.repeatForever(walkAction)
        node.run(repeatWalk, withKey: "walkAnimation")
    }

    private func stopWalkingAnimation() {
        isAnimating = false
        node.removeAction(forKey: "walkAnimation")
        node.texture = idleFrame // Kembalikan ke posisi berdiri biasa
    }
}
