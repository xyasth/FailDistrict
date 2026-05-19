import SpriteKit

class MainMenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        
    }
    
    // VERSI MAC: Menggunakan mouseDown dan NSEvent
    override func mouseDown(with event: NSEvent) {
        // Cari koordinat ujung kursor mouse saat di-klik
        let location = event.location(in: self)
        
        // Deteksi objek apa yang ada di koordinat tersebut
        let touchedNode = atPoint(location)
        
        // Jika yang di-klik bernama "play_button", mulai game!
        if touchedNode.name == "play_button" {
            startGame()
        }
    }
    
    private func startGame() {
        if let gameScene = GameScene(fileNamed: "GameScene") {
            gameScene.scaleMode = .aspectFill
            let transition = SKTransition.crossFade(withDuration: 1.0)
            view?.presentScene(gameScene, transition: transition)
        }
    }
}
