//
//  ViewController.swift
//  HeAR-iOS
//
//  Created by Francesco Valela on 2019-01-26.
//  Copyright © 2019 Francesco Valela. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit
import Speech

class ViewController: UIViewController, ARSKViewDelegate, SFSpeechRecognizerDelegate {

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var recognizedText: String = ""
  
    @IBOutlet var sceneView: ARSKView!
    
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet var recordButton: UIButton!
    
    var labelNode: SKLabelNode?
    
    var shadowNode: SKLabelNode?
    
    let attributes: [NSAttributedString.Key : Any] = [.strokeWidth: -2.0,
                                                      .strokeColor: UIColor.black,
                                                      .foregroundColor: UIColor.white]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Load the SKScene from 'Scene.sks'
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
        }
        
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        // Make the authorization request
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            // The authorization status results in changes to the
            // app’s interface, so process the results on the app’s
            // main queue.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.recordButton.isEnabled = true
                    
                case .denied:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("User denied accessto speech recognition", for: .disabled)
                    
                case .restricted:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSKViewDelegate
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        var node: SKLabelNode?
        
        if let anchor = anchor as? Anchor {
            switch(anchor.type?.rawValue) {
            case "frontLabel":
                node = SKLabelNode(attributedText: NSMutableAttributedString(string: " ", attributes: attributes))
                labelNode = node
                break
            default:
                node = SKLabelNode(attributedText: NSMutableAttributedString(string: " ", attributes: attributes))
                labelNode = node
            }
        }
            
        node?.horizontalAlignmentMode = .center
        node?.verticalAlignmentMode = .center
        node?.numberOfLines = 2
        node?.preferredMaxLayoutWidth = CGFloat(126.5)
        node?.lineBreakMode = .byTruncatingHead
        
        return node;
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func replaceSubtitles(newSubs: String) {
        self.labelNode?.attributedText = NSAttributedString(string: newSubs, attributes: attributes)
    }
  
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.recognizedText = result.bestTranscription.formattedString
                self.replaceSubtitles(newSubs: self.recognizedText)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
                self.recordButton.setTitle("Start Recording", for: [])
            }
        }
        
        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
        self.recognizedText = "(Go ahead, I'm listening)"
    }
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setTitle("Start Recording", for: [])
        } else {
            recordButton.isEnabled = false
            recordButton.setTitle("Recognition Not Available", for: .disabled)
        }
    }
    
    @IBAction func onRecordButtonTap(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("Stopping", for: .disabled)
        } else {
            do {
                try startRecording()
                recordButton.setTitle("Stop Recording", for: [])
            } catch {
                recordButton.setTitle("Recording Not Available", for: [])
            }
        }
    }
}
