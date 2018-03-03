//
//  ViewController.swift
//  ImageAnalysis
//
//  Created by 李超逸 on 2018/03/03.
//  Copyright © 2018 李超逸. All rights reserved.
//

import Alamofire
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var choosePhotoButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var progressView: UIProgressView!
    
    var tags: [String]?
    var colors: [PhotoColor]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func choosePhotoButonPressed(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
            picker.modalPresentationStyle = .fullScreen
        }
        
        present(picker, animated: true)
    }
    
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            print("Info did not have the required UIImage for the Original Image")
            dismiss(animated: true)
            return
        }
        
        imageView.image = image
        
        choosePhotoButton.isHidden = true
        progressView.progress = 0.0
        progressView.isHidden = false
        activityIndicatorView.startAnimating()
        
        upload(
            image: image,
            progressCompletion: { [unowned self] percent in
                self.progressView.setProgress(percent, animated: true)
            },
            completion: { [unowned self] tags, colors in
                self.choosePhotoButton.isHidden = false
                self.progressView.isHidden = true
                self.activityIndicatorView.stopAnimating()
                
                self.tags = tags
                self.colors = colors
                
//                self.performSegue(withIdentifier: "ShowResults", sender: self)
        })
        
        dismiss(animated: true)
    }
}

extension ViewController: UINavigationControllerDelegate {
}

extension ViewController {
    func upload(image: UIImage,
                progressCompletion: @escaping (_ percent: Float) -> Void,
                completion: @escaping (_ tags: [String], _ colors: [PhotoColor]) -> Void) {
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            print("Could not get JPEG representation of UIImage")
            return
        }
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imageData,
                                         withName: "imagefile",
                                         fileName: "image.jpg",
                                         mimeType: "image/jpeg")
        },
            to: "http://api.imagga.com/v1/content",
            headers: ["Authorization": "Basic YWNjXzcxNTEwZTczNTc1YmVmZjpkOTMwZjA4ZDRlNWVlMWI5MTg5NzEyNjlmNzc5OTBlYQ=="],
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.uploadProgress { progress in
                        progressCompletion(Float(progress.fractionCompleted))
                    }
                    upload.validate()
                    upload.responseJSON { response in
                        guard response.result.isSuccess else {
                            print("Error while uploading file: \(response.result.error)")
                            completion([String](), [PhotoColor]())
                            return
                        }
                        
                        guard let responseJSON = response.result.value as? [String: Any],
                            let uploadedFiles = responseJSON["uploaded"] as? [[String: Any]],
                            let firstFile = uploadedFiles.first,
                            let firstFileID = firstFile["id"] as? String else {
                                print("Invalid information received from service")
                                completion([String](), [PhotoColor]())
                                return
                        }
                        
                        print("Content uploaded with ID: \(firstFileID)")
                        
                        self.downloadTags(contentID: firstFileID) { tags in
                            completion(tags, [PhotoColor]())
                        }
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
        }
        )
    }
    
    func downloadTags(contentID: String, completion: @escaping ([String]) -> Void) {
        Alamofire.request(
            "http://api.imagga.com/v1/tagging",
            parameters: ["content": contentID],
            headers: ["Authorization": "Basic YWNjXzcxNTEwZTczNTc1YmVmZjpkOTMwZjA4ZDRlNWVlMWI5MTg5NzEyNjlmNzc5OTBlYQ=="]
            )
            .responseJSON { response in
                guard response.result.isSuccess else {
                    print("Error while fetching tags: \(response.result.error)")
                    completion([String]())
                    return
                }
                
                guard let responseJSON = response.result.value as? [String: Any],
                    let results = responseJSON["results"] as? [[String: Any]],
                    let firstObject = results.first,
                    let tagsAndConfidences = firstObject["tags"] as? [[String: Any]] else {
                        print("Invalid tag information received from the service")
                        completion([String]())
                        return
                }
                
                let tags = tagsAndConfidences.flatMap({ dict in
                    return dict["tag"] as? String
                })
                
                completion(tags)
        }
    }
}
