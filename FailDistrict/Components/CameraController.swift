//
//  CameraController.swift
//  FailDistrict
//
//  Created by Hansel Meinhard on 13/05/26.
//

import SpriteKit

class CameraController {
    let cameraNode: SKCameraNode
    let targetNode: SKNode
    let viewSize: CGSize
    let mapSize: CGSize
    let smoothing: CGFloat = 0.1
    
    init(cameraNode: SKCameraNode, targetNode: SKNode, viewSize: CGSize, mapSize: CGSize) {
        self.cameraNode = cameraNode
        self.targetNode = targetNode
        self.viewSize = viewSize
        self.mapSize = mapSize
    }
    
    func update() {
        // Horizontal Smooth Follow
        let distanceX = targetNode.position.x - cameraNode.position.x
        cameraNode.position.x += distanceX * smoothing
        
        // Fixed Y-Axis
        cameraNode.position.y = viewSize.height / 2
        
        // Camera Bounds dengan Kalkulasi Skala Zoom
        let visibleWidth = viewSize.width * cameraNode.xScale
        let cameraMinX = visibleWidth / 2
        let cameraMaxX = mapSize.width - (visibleWidth / 2)
        
        if cameraNode.position.x < cameraMinX {
            cameraNode.position.x = cameraMinX
        } else if cameraNode.position.x > cameraMaxX {
            cameraNode.position.x = cameraMaxX
        }
    }
}
