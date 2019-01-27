//
//  Scene.swift
//  HeAR-iOS
//
//  Created by Francesco Valela on 2019-01-26.
//  Copyright © 2019 Francesco Valela. All rights reserved.
//

import SpriteKit
import ARKit
import Vision

class Scene: SKScene {
    
    var sceneView: ARSKView?
    
    var isWorldSetUp = false
    
    var isFaceSet = false;
    
    var facePosition: CGPoint?
    
    var face: VNFaceLandmarkRegion2D?
    
    var faceBox: CGRect?
    
    var frontAnchor: Anchor?
    
    var counter: Int = 0
    
    override func didMove(to view: SKView) {
        // Setup your scene here
        sceneView = view as? ARSKView
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if !isWorldSetUp && isFaceSet {
            setUpWorld()
        }
        
        if isWorldSetUp && isFaceSet && counter % 600 == 0 {
            setUpWorld()
        }
        
        counter = counter + 1
    }
    
    private func setUpWorld() {
        guard let currentFrame = sceneView?.session.currentFrame
            else { return }
        
        isWorldSetUp = true
    
        // Create a transform with a translation of 0.2 meters in front of the camera
        var translation = matrix_identity_float4x4
        
        guard let box = faceBox
            else { return }
        let area = (1 + box.height * 5) * (1 + box.width * 5)
        let distance = Float(7-area)
        translation.columns.3.z = -distance
        translation.columns.3.x = Float(facePosition?.x ?? 0) - 1/distance
        translation.columns.3.y = Float(facePosition?.y ?? 0) - 1/distance
        let transform = currentFrame.camera.transform * translation
    
        // Add a new anchor to the session
        if frontAnchor != nil {
            sceneView?.session.remove(anchor: frontAnchor!)
        }
        frontAnchor = Anchor(transform: transform)
        frontAnchor?.type = NodeType.frontLabel
        frontAnchor?.size = distance
        sceneView?.session.add(anchor: frontAnchor!)
        
    }
    
    func setFace(face: VNFaceLandmarkRegion2D?, boundingBox: CGRect?) {
        self.face = face
        self.faceBox = boundingBox
        isFaceSet = true
    }
}
