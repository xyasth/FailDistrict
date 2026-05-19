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
    
    // State game sederhana
    private var gameState: GameState = .playing
    
    // Untuk pause game
    private var pauseMenuContainer: SKNode!
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -15.0)
        backgroundColor = .black
        
        parseLevelFromSKS()
        setupPlayer()
        setupTreeObstacleEntities()
        setupFruitDropEntities()
        setupCamera()
        setupPauseButton()
        setupPauseMenuAssetBased()
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
        if gameState == .dead && event.charactersIgnoringModifiers?.lowercased() == "r" {
            restartScene()
            return
        }
        
        if event.keyCode == 53 {
            toggleGamePause()
            return
        }
        
        if !self.isPaused {
            playerControl?.handleKeyDown(event.keyCode)
        }
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

    func didBegin(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node

        guard gameState == .playing else { return }
        
        if handleTreeTriggerContact(maskA, maskB, nodeA: nodeA, nodeB: nodeB) { return }
        if handleFruitTriggerContact(maskA, maskB, nodeA: nodeA, nodeB: nodeB) { return }
        if handlePlayerHazardContact(maskA, maskB, nodeA: nodeA, nodeB: nodeB) { return }
        _ = handleFruitGroundContact(maskA, maskB, nodeA: nodeA, nodeB: nodeB)
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
    
    private func setupPauseMenuAssetBased() {
            guard let camera = self.camera else { return }
            
            // 1. Membuat Wadah Utama
            pauseMenuContainer = SKNode()
            pauseMenuContainer.zPosition = 200 // Sangat tinggi agar di depan semuanya
            pauseMenuContainer.isHidden = true // Sembunyikan awalnya
            
            // 2. Layar Peredup (Overlay) - Tetap pakai kode karena sangat mudah
            // Membuat layar hitam transparan memenuhi layar
            let dimmer = SKSpriteNode(color: NSColor.black.withAlphaComponent(0.6), size: self.size)
            // Koordinat 0,0 di kamera adalah tepat di tengah layar MacBook
            dimmer.position = CGPoint.zero
            pauseMenuContainer.addChild(dimmer)
            
            // 3. Panel Latar Belakang Utama
            // Asumsikan nama gambar panel latar belakangmu di Assets adalah: "pause_menu_panel"
            let panel = SKSpriteNode(imageNamed: "frame_button")
            panel.position = CGPoint.zero // Letakkan tepat di tengah (senter)
            pauseMenuContainer.addChild(panel)
            
            // --- Memasukkan Tombol-tombol di Atas Panel ---
            // Posisinya dihitung relatif terhadap tengah panel (0,0)

            // Jarak vertikal antar tombol
            let verticalSpacing: CGFloat = 60
            // Y-posisi awal tombol paling atas (di atas titik tengah panel)
            let buttonYStart: CGFloat = 45
            
            // A. Tombol Besar: RESUME
            // Asumsikan gambar lengkap tombol dengan teksnya bernama: "button_resume_asset"
            let resumeBtn = SKSpriteNode(imageNamed: "resume")
            resumeBtn.name = "resume_button_asset" // Nama unik sensor klik
            resumeBtn.position = CGPoint(x: 0, y: buttonYStart)
            pauseMenuContainer.addChild(resumeBtn)
            
            // B. Tombol Besar: RESTART
            // Asumsikan gambar bernama: "button_restart_asset"
            let restartBtn = SKSpriteNode(imageNamed: "restart")
            restartBtn.name = "restart_button_asset" // Nama unik sensor klik
            restartBtn.position = CGPoint(x: 0, y: buttonYStart - verticalSpacing)
            pauseMenuContainer.addChild(restartBtn)
            
            // C. Tombol Kecil: BACK TO HOME (di bawah)
            // Asumsikan gambar bernama: "button_back_home_asset"
            let backHomeBtn = SKSpriteNode(imageNamed: "back_to_home")
            backHomeBtn.name = "back_home_button_asset" // Nama unik sensor klik
            // Letakkan lebih ke bawah
            backHomeBtn.position = CGPoint(x: 0, y: buttonYStart - 2 * verticalSpacing - 20)
            pauseMenuContainer.addChild(backHomeBtn)
            
            
            // --- Ikon-ikon di Atas Tombol Besar ---
            
            // Y-posisi ikon-ikon di atas panel
            let iconY: CGFloat = 115
            // Jarak antar ikon horizontal
            let iconSpacing: CGFloat = 60

            // D. Ikon Suara (Speaker)
            // Asumsikan gambar ikon suara sedang menyala: "icon_sound_on"
            let soundIcon = SKSpriteNode(imageNamed: "sfx")
            soundIcon.name = "sound_toggle_asset" // Nama unik sensor klik
            // Letakkan agak ke kiri
            soundIcon.position = CGPoint(x: -iconSpacing / 2, y: iconY)
            pauseMenuContainer.addChild(soundIcon)
            
            // E. Ikon Musik (Notasi)
            // Asumsikan gambar ikon musik menyala: "icon_music_on"
            let musicIcon = SKSpriteNode(imageNamed: "music")
            musicIcon.name = "music_toggle_asset" // Nama unik sensor klik
            // Letakkan agak ke kanan
            musicIcon.position = CGPoint(x: iconSpacing / 2, y: iconY)
            pauseMenuContainer.addChild(musicIcon)
            
            
            // 4. Tempelkan seluruh wadah UI ini ke Kamera
            camera.addChild(pauseMenuContainer)
        }
    
    private func setupPauseButton() {
            guard let camera = self.camera else { return }
            
            // 1. Panggil gambar tombol kuning bundarmu.
            // GANTI "button_pause_yellow" dengan nama asli gambar tombolmu di Assets
            let pauseButton = SKSpriteNode(imageNamed: "pause")
            
            // Pastikan nama ini SAMA dengan yang ada di deteksi klik mouseDown
            pauseButton.name = "pause_button"
            pauseButton.zPosition = 100 // Harus lebih rendah dari wadah menu pause (200)
        
            // Jika ukuran gambar aslinya terlalu besar, buka komentar baris di bawah ini
            // dan sesuaikan angkanya agar pas di layar:
            // pauseButton.size = CGSize(width: 60, height: 60)
            
            // 2. Hitung posisi Pojok Kanan Atas
            let padding: CGFloat = 50 // Jarak dari pinggir layar
            let xPos = (self.size.width / 2) - padding
            let yPos = (self.size.height / 2) - padding
            pauseButton.position = CGPoint(x: xPos, y: yPos)
            
            // 3. Masukkan ke dalam kamera
            camera.addChild(pauseButton)
        }
    
    override func mouseDown(with event: NSEvent) {
            let location = event.location(in: self)
            let touchedNode = atPoint(location)
            
            // A. Cek apakah tombol pause kuning di pojok diklik
            if touchedNode.name == "pause_button" {
                toggleGamePause()
                return // Stop di sini agar kode lain tidak ikut tereksekusi
            }
            
            // B. Cek tombol-tombol Menu Pause (HANYA saat game sedang pause)
            if self.isPaused, let nodeName = touchedNode.name {
                
                switch nodeName {
                case "resume_button_asset":
                    print("▶️ Melanjutkan Game")
                    toggleGamePause()
                    
                case "restart_button_asset":
                    print("🔄 Restart Game")
                    toggleGamePause() // Cairkan dulu gamenya
                    restartScene()    // Panggil fungsi restart bawaanmu
                    
                case "back_home_button_asset":
                    print("🏠 Kembali ke Home")
                    toggleGamePause()
                    if let mainMenu = MainMenuScene(fileNamed: "MainMenuScene") {
                        mainMenu.scaleMode = self.scaleMode
                        self.view?.presentScene(mainMenu, transition: .crossFade(withDuration: 1.0))
                    }
                    
                case "sound_toggle_asset":
                    print("🔈 On/Off Suara")
                    
                case "music_toggle_asset":
                    print("🎵 On/Off Musik")
                    
                default:
                    break
                }
                return
            }
            
            // (Kalau kamu punya kode klik untuk hal lain seperti menembak, taruh di bawah sini)
        }
        
        private func toggleGamePause() {
            // Balikkan status pause bawaan mesin game
            self.isPaused = !self.isPaused
            
            // Tampilkan wadah menu jika game berhenti, sembunyikan jika game jalan
            pauseMenuContainer.isHidden = !self.isPaused
        }
}
