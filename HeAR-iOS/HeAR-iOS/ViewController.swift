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
import Vision

class ViewController: UIViewController, ARSKViewDelegate, SFSpeechRecognizerDelegate {

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var recognizedText: String = ""
  
    @IBOutlet weak var sceneView: ARSKView!
    
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet var recordButton: UIButton!
    
    var labelNode: SKLabelNode?
    
    var shadowNode: SKLabelNode?
    
    var attributes: [NSAttributedString.Key : Any]?
    
    var subtitleColor: UIColor = UIColor.white
    
    private var scanTimer: Timer?
    
    private var currentSubtitlePtr: Int = 0
    private var maxSubtitlePtr: Int = Util.MAX_CAPATION_LABEL_SIZE
    
    private var scannedFaceViews = [UIView]()
    
    private var newSubs: String = " "
    
    private var isFaceSet = false
    
    
    
    //get the orientation of the image that correspond's to the current device orientation
    private var imageOrientation: CGImagePropertyOrientation {
        switch UIDevice.current.orientation {
        case .portrait: return .right
        case .landscapeRight: return .down
        case .portraitUpsideDown: return .left
        case .unknown: fallthrough
        case .faceUp: fallthrough
        case .faceDown: fallthrough
        case .landscapeLeft: return .up
        }
    }
    
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
        
        recordButton.setImage(UIImage(named: "iconfinder_ic_mic_white_bg"), for:[])
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
        
        scanTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(scanForFaces), userInfo: nil, repeats: true)
        
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
        
        scanTimer?.invalidate()
        sceneView.session.pause()
    }
    
    // MARK: - ARSKViewDelegate
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        var node: SKLabelNode?
        
        if let anchor = anchor as? Anchor {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            attributes = [.strokeWidth: -3.0,
                          .strokeColor: UIColor.black,
                          .foregroundColor: subtitleColor,
                          .font: UIFont(name: "HelveticaNeue-Bold", size: CGFloat(((anchor.size ?? 0.0) + 1.0) * 12.0 ))!,
                          .paragraphStyle: paragraph]
            switch(anchor.type?.rawValue) {
            case "frontLabel":
                node = SKLabelNode(attributedText: NSMutableAttributedString(string: newSubs, attributes: attributes))
                labelNode = node
                node?.preferredMaxLayoutWidth = CGFloat(((anchor.size ?? 5.0) + 1.0) * 125.0)
                break
            default:
                node = SKLabelNode(attributedText: NSMutableAttributedString(string: newSubs, attributes: attributes))
                labelNode = node
                node?.preferredMaxLayoutWidth = CGFloat(anchor.size ?? 5 * 75.0)
            }
        }
        
        node?.horizontalAlignmentMode = .center
        node?.verticalAlignmentMode = .center
        node?.numberOfLines = 2
        
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
    
    func replaceSubtitles() {
        self.labelNode?.attributedText = NSAttributedString(string: self.newSubs, attributes: attributes)
    }
    
    
    @IBAction func onWhiteSubtitlesPressed(_ sender: Any) {
        subtitleColor = UIColor.white
        attributes?[.foregroundColor] = UIColor.white
        replaceSubtitles()
        
    }
    
    @IBAction func onYellowSubtitlesPressed(_ sender: Any) {
        subtitleColor = UIColor.yellow
        attributes?[.foregroundColor] = UIColor.yellow
        replaceSubtitles()
    }
    
    
    @IBAction func onCyanSubtitlesPressed(_ sender: Any) {
        subtitleColor = UIColor.cyan
        attributes?[.foregroundColor] = UIColor.cyan
        replaceSubtitles()
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
                if(self.recognizedText.count - self.currentSubtitlePtr > self.maxSubtitlePtr){
                    
                    // entire recognized text does not fit in the label
                    let innerSub = self.substring(str: self.recognizedText, front: self.currentSubtitlePtr, back: -(self.recognizedText.count - (self.currentSubtitlePtr + self.maxSubtitlePtr/2)))
                    let lastSpace = self.findLastSpace(str: innerSub)+1
                    self.currentSubtitlePtr = self.currentSubtitlePtr + lastSpace
                    self.newSubs = self.substring(str: self.recognizedText, front: self.currentSubtitlePtr, back: 0)
                }else{
                    if (self.currentSubtitlePtr > self.recognizedText.count) {
                        self.currentSubtitlePtr = 0
                        let innerSub = self.substring(str: self.recognizedText, front: self.currentSubtitlePtr, back: -self.maxSubtitlePtr/2)
                        let lastSpace = self.findLastSpace(str: innerSub)+1
                        self.currentSubtitlePtr = self.currentSubtitlePtr + lastSpace
                    }
                    self.newSubs = self.substring(
                        str: self.recognizedText, front: self.currentSubtitlePtr, back: 0)
                }
                
                self.replaceSubtitles()
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
        
        self.currentSubtitlePtr = 0
        self.maxSubtitlePtr = Util.MAX_CAPATION_LABEL_SIZE
        
        // Let the user know to start talking.
        self.recognizedText = " "
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
            recordButton.setImage(UIImage(named: "iconfinder_ic_mic_white_bg"), for:[])
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("Stopping", for: .disabled)
        } else {
            do {
                recordButton.setImage(UIImage(named: "iconfinder_ic_mic_darkgrey_bg"), for:[])
                self.isFaceSet = false
                self.newSubs = " "
                self.currentSubtitlePtr = 0
                self.maxSubtitlePtr = Util.MAX_CAPATION_LABEL_SIZE
                try startRecording()
                recordButton.setTitle("Stop Recording", for: [])
            } catch {
                recordButton.setTitle("Recording Not Available", for: [])
            }
        }
    }
    
    func setMicrophoneButton() {
        
    }
    
    @objc
    private func scanForFaces() {
        //remove the test views and empty the array that was keeping a reference to them
        _ = scannedFaceViews.map { $0.removeFromSuperview() }
        scannedFaceViews.removeAll()
        
        //get the captured image of the ARSession's current frame
        guard let capturedImage = sceneView.session.currentFrame?.capturedImage else { return }
        
        let image = CIImage.init(cvPixelBuffer: capturedImage)
        
        let detectFaceRequest = VNDetectFaceRectanglesRequest { [weak self] (request, error) in
            
            DispatchQueue.main.async {
                //Loop through the resulting faces and add a red UIView on top of them.
                if let faces = request.results as? [VNFaceObservation] {
                    var i = 0
                    for face in faces {
                        let faceView = UITextView(frame: (self?.faceFrame(from: face.boundingBox))!)
                        faceView.text = "Face: " + String.init(i)
                        
                        faceView.backgroundColor = .red
                        
                        if(!(self?.isFaceSet)!) {
                            (self?.sceneView.scene as! Scene).setFace(face: face.landmarks?.outerLips, boundingBox: face.boundingBox)
                            self?.isFaceSet = true
                        }
                        
                        i = i + 1
                    }
                }
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                try? VNImageRequestHandler(ciImage: image, orientation: self.imageOrientation).perform([detectFaceRequest])
            }
        }
    }
    
    private func faceFrame(from boundingBox: CGRect) -> CGRect {
        
        //translate camera frame to frame inside the ARSKView
        let origin = CGPoint(x: boundingBox.minX * sceneView.bounds.width, y: (1 - boundingBox.maxY) * sceneView.bounds.height)
        let size = CGSize(width: boundingBox.width * sceneView.bounds.width, height: boundingBox.height * sceneView.bounds.height)
        
        return CGRect(origin: origin, size: size)
    }
    
    private func substring(str: String, front: Int, back: Int) -> String{
        let start = str.index(str.startIndex, offsetBy: front)
        let end = str.index(str.endIndex, offsetBy: back)
        let range = start..<end
        
        return String(str[range])
    }
    
    private func findLastSpace(str: String) -> Int {
        var lastIdx = 0
        var i = 0
        for c in str {
            if(c == " "){
                lastIdx = i
            }
            i = i + 1
        }
        return lastIdx
    }
}
