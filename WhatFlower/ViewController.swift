//
//  ViewController.swift
//  WhatFlower
//
//  Created by Cemal Arda KIZILKAYA on 16.11.2018.
//  Copyright © 2018 Cemal Arda KIZILKAYA. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if  let imagePicked = info[.originalImage] as? UIImage {
        
            guard let ciimage = CIImage(image: imagePicked) else {
                fatalError("Could not convert image")
            }
            
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    // function that processes the photo taken by the user
    func detect(image: CIImage) {
        
        guard  let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Could not import model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            let result = request.results?.first as! VNClassificationObservation
            self.navigationItem.title = result.identifier.capitalized
            self.requestFlowerInfo(flowerName: result.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    func requestFlowerInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            
            if response.result.isSuccess {
                print("Result of the query----------\n \(response.result)")
                
                let flowerJSON : JSON = JSON(response.result.value!)
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDesc = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.infoLabel.text = flowerDesc
            }
        }
    }
    

    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
    }
    
}

