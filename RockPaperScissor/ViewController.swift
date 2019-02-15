//
//  ViewController.swift
//  RockPaperScissor
//
//  Created by Rupika Sompalli on 15/02/19.
//  Copyright © 2019 Venkata. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum HandSign: String {
    case rock = "Rock"
    case paper = "Paper"
    case scissor = "Scissor"
    case noSign = "Negative"
}

class ViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var msg : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureCamera()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }

    func configureCamera() {
        
        //Start capture session
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        captureSession.startRunning()
        
        // Add input for capture
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let captureInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(captureInput)
        
        // Add preview layer to our view to display the open camera screen
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        // Add output of capture
        /* Here we set the sample buffer delegate to our viewcontroller whose callback
         will be on a queue named - videoQueue */
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self as! AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        /* Initialise CVPixelBuffer from sample buffer
         CVPixelBuffer is the input type we will feed our coremlmodel .
         */
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        /* Initialise Core ML model
         We create a model container to be used with VNCoreMLRequest based on our HandSigns Core ML model.
         */
        guard let handSignsModel = try? VNCoreMLModel(for: rock3().model) else { return }
        
        /* Create a Core ML Vision request
         The completion block will execute when the request finishes execution and fetches a response.
         */
        let request =  VNCoreMLRequest(model: handSignsModel) { (finishedRequest, err) in
            
            /* Dealing with the result of the Core ML Vision request
             The request's result is an array of VNClassificationObservation object which holds
             identifier - The prediction tag we had defined in our Custom Vision model - FiveHand, FistHand, VictoryHand, NoHand
             confidence - The confidence on the prediction made by the model on a scale of 0 to 1
             */
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
            
            /* Results array holds predictions iwth decreasing level of confidence.
             Thus we choose the first one with highest confidence. */
            guard let firstResult = results.first else { return }
            
            print(firstResult.identifier)
            
            var predictionString = ""
            
            /* Depending on the identifier we set the UILabel text with it's confidence.
             We update UI on the main queue. */
            DispatchQueue.main.async {
                switch firstResult.identifier {
                case HandSign.rock.rawValue:
                    predictionString = "Rock"
                case HandSign.paper.rawValue:
                    predictionString = "Paper"
                case HandSign.scissor.rawValue:
                    predictionString = "Scissor"
                case HandSign.noSign.rawValue:
                    predictionString = "No Sign"
                default:
                    break
                }
                self.msg.text = predictionString //+ "(\(firstResult.confidence))"
            }
        }
        
        /* Perform the above request using Vision Image Request Handler
         We input our CVPixelbuffer to this handler along with the request declared above.
         */
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    

}
