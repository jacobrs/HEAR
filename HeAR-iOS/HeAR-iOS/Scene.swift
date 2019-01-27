//
//  Scene.swift
//  HeAR-iOS
//
//  Created by Francesco Valela on 2019-01-26.
//  Copyright © 2019 Francesco Valela. All rights reserved.
//

import SpriteKit
import ARKit

class Scene: SKScene {
    
    var sceneView: ARSKView?
    
    var isWorldSetUp = false
    
    override func didMove(to view: SKView) {
        // Setup your scene here
        sceneView = view as? ARSKView
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if !isWorldSetUp {
            setUpWorld()
        }
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let sceneView = self.view as? ARSKView else {
//            return
//        }
//
//        // Create anchor using the camera's current position
//        if let currentFrame = sceneView.session.currentFrame {
//
//            // Create a transform with a translation of 0.2 meters in front of the camera
//            var translation = matrix_identity_float4x4
//            translation.columns.3.z = -0.5
//            let transform = simd_mul(currentFrame.camera.transform, translation)
//
//            // Add a new anchor to the session
//            let anchor = ARAnchor(transform: transform)
//            sceneView.session.add(anchor: anchor)
//
//        }
//    }
    
    private func setUpWorld() {
        guard let currentFrame = sceneView?.session.currentFrame
            else { return }
        
        isWorldSetUp = true
        
        // Create a transform with a translation of 0.2 meters in front of the camera
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.5
        let transform = currentFrame.camera.transform * translation
    
        // Add a new anchor to the session
        let frontAnchor = Anchor(transform: transform)
        frontAnchor.type = NodeType.frontLabel
        sceneView?.session.add(anchor: frontAnchor)
        let backAnchor = Anchor(transform: transform)
        backAnchor.type = NodeType.backLabel
        sceneView?.session.add(anchor: backAnchor)
    }
}
