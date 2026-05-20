import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. UBAH RUTE: Membuka MainMenuScene terlebih dahulu
        if let scene = MainMenuScene(fileNamed: "MainMenuScene") {
            
            scene.scaleMode = .aspectFill
            
            if let view = self.skView {
                view.presentScene(scene)
                
                // 2. OPTIMASI RENDER
                // Ubah menjadi 'true' agar urutan tumpukan gambar mutlak mengikuti nilai zPosition yang sudah kita atur (100, 200, dsb)
                view.ignoresSiblingOrder = true
                
                view.showsFPS = true
                view.showsNodeCount = true
                
                // 3. ESTETIKA UI
                // Matikan garis hijau (x-ray) fisika agar tampilan Main Menu yang rapi tidak terganggu
                view.showsPhysics = false
            }
        }
    }
}
