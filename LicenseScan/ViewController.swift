//
//  ViewController.swift
//  LicenseScan
//
//  Created by Manish Sharma on 25/02/21.
//  Copyright © 2021 Manish Sharma. All rights reserved.
//

import UIKit
import Vision
import MobileCoreServices

class ViewController: UIViewController {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblSannedText: UILabel!
    var objectBounds = CGRect()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Actions
    @IBAction func addPhotoAction(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.isEditing = false
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: - Custom methods
    func textRecognition(image: CGImage) {
        // 1. Request
        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: self.handleDetectedText)
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.recognitionLanguages = ["en_US"]
        textRecognitionRequest.usesLanguageCorrection = false
//        textRecognitionRequest.customWords = ["HR26DK8337", "TN09EF8790", "MH12FE8999", "TS07EW9812", "DL7CQ19399"]
        
        // 2. Request Handler
        let textRequest = [textRecognitionRequest]
        let imageRequestHandler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 3. Perform request
                try imageRequestHandler.perform(textRequest)
            } catch let error {
                print("Error: \(error)")
            }
        }
        
        
    }
    
    func handleDetectedText(request: VNRequest?, error: Error?) {
        if let error = error {
            print("ERROR: \(error.localizedDescription)")
        }
        
        guard let results = request?.results, results.count > 0 else {
            print("No text recognised in the given image")
            return
        }
        
        for result in results {
            if let observation = result as? VNRecognizedTextObservation {
                
                guard let bestCandidate = observation.topCandidates(1).first else {
                    print("No candidate")
                    continue
                }

                print("Found this candidate: \(bestCandidate.string)")
                DispatchQueue.main.async {
                    self.lblSannedText.text = bestCandidate.string
                }

                for text in observation.topCandidates(1) {
                    // TODO: Draw bounding box
                    DispatchQueue.main.async {
                        do {
                            var t:CGAffineTransform = CGAffineTransform.identity;
                            t = t.scaledBy( x: (self.imgView.image?.size.width)!, y: -(self.imgView.image?.size.height)!);
                            t = t.translatedBy(x: 0, y: -1 );
                            self.objectBounds = observation.boundingBox.applying(t)
                            let newString = text.string.replacingOccurrences(of: " ", with: "")
                            // print(newString)
                            let pattern = "[A-Z]{2}[A-Za-z0-9_]{2}[A-Z]{2}[0-9]{4}"
                            let resultOfRegEx = newString.range(of: pattern, options: .regularExpression)
                            if((resultOfRegEx) != nil){
                                let imageWithBoundingBox =  self.drawRectangleOnImage(image: self.imgView.image!, x: Double(self.objectBounds.minX), y: Double(self.objectBounds.minY), width: Double(self.objectBounds.width), height: Double(self.objectBounds.height))
                                self.imgView.image = imageWithBoundingBox
                                self.lblSannedText.text = text.string
                            }
                        }
                    }
                }
            }
        }
    }
    
    func drawRectangleOnImage(image: UIImage, x:Double, y:Double, width:Double, height:Double) -> UIImage{
        let imageSize = image.size
        let scale:CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        let context = UIGraphicsGetCurrentContext()
        image.draw(at: CGPoint.zero)
        let rectangelTodraw = CGRect(x:x, y:y, width:width, height:height)
        
        context?.setStrokeColor(UIColor.red.cgColor)
        context?.setLineWidth(5.0)
        context?.addRect(rectangelTodraw)
        context?.drawPath(using: .stroke)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
       
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let capturedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
        // Set image on ImageView
            imgView.contentMode = .scaleAspectFit
            imgView.image = capturedImage
            // Start vision task
            self.textRecognition(image:(imgView.image?.cgImage)!)
        }
        
        dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UINavigationControllerDelegate {
    
}

