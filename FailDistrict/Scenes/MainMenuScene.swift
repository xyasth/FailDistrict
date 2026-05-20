import SpriteKit

class MainMenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        setupMenuLayout()
    }
    
    private func setupMenuLayout() {
            // Background
            let background = SKSpriteNode(imageNamed: "main_menu")
            background.position = CGPoint(x: 0, y: 0)
            background.zPosition = -1
            background.size = self.size
            addChild(background)
            
            // Start Button
            let startButton = SKSpriteNode(imageNamed: "start")
            startButton.name = "start_button"
            startButton.zPosition = 1
            startButton.setScale(0.9)
            
            startButton.position = CGPoint(x: size.width * 0.21, y: -size.height * 0.08)
            addChild(startButton)
            
            // Setting Top Right
            let iconPadding: CGFloat = 60

            let rightEdge = size.width / 2
            let topEdge = size.height / 2
            
            let musicIcon = SKSpriteNode(imageNamed: "sfx")
            musicIcon.name = "music_toggle"
            musicIcon.position = CGPoint(x: rightEdge - iconPadding, y: topEdge - iconPadding)
            musicIcon.setScale(0.9)
            addChild(musicIcon)
            
            let soundIcon = SKSpriteNode(imageNamed: "music")
            soundIcon.name = "sound_toggle"
            soundIcon.position = CGPoint(x: musicIcon.position.x - 70, y: topEdge - iconPadding)
            soundIcon.setScale(0.9)
            addChild(soundIcon)
        }
    
    // SENSOR KLIK MAC
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let touchedNode = atPoint(location)
        
        if touchedNode.name == "start_button" {
            let scaleDown = SKAction.scale(to: 0.8, duration: 0.1)
            let scaleUp = SKAction.scale(to: 0.9, duration: 0.1)
            let sequence = SKAction.sequence([scaleDown, scaleUp])
            
            touchedNode.run(sequence) {
                self.goToGameScene()
            }
        }
        
        // Logic untuk Sound & Music
    }
    
    private func goToGameScene() {
        if let scene = GameScene(fileNamed: "GameScene") {
            scene.scaleMode = .aspectFill
            let transition = SKTransition.crossFade(withDuration: 0.5)
            view?.presentScene(scene, transition: transition)
        }
    }
}
