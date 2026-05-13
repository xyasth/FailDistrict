import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Buat panggung dengan ukuran standar Mac
        let scene = GameScene(size: CGSize(width: 1024, height: 768))
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene.scaleMode = .aspectFill
        
        if let view = self.skView {
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
            
            // X-Ray fisik dinyalakan agar mempermudah kamu mendesain level
            view.showsPhysics = true
        }
    }
}
