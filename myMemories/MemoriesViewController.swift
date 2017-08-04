//
//  MemoriesViewController.swift
//  myMemories
//
//  Created by Adriano Ronszcka on 27/07/17.
//  Copyright © 2017 Adriano Ronszcka. All rights reserved.
//

import UIKit

import Photos
import AVFoundation
import Speech

class MemoriesViewController: UICollectionViewController, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    
    var memories = [URL]()

    override func viewDidAppear(_ animated: Bool) {
        checkPermission()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMemory))
        
        loadMemories()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func checkPermission(){
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission() == .granted
        
        let transcriberAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let authorized = photosAuthorized && recordingAuthorized && transcriberAuthorized
        
        if authorized == false {
            if let permissionsViewController =
                storyboard?.instantiateViewController(withIdentifier: "Permissions"){
                    
                    navigationController?.present(permissionsViewController, animated: true)
            }
        }
     
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
    
    func loadMemories(){
        memories.removeAll()
        
        guard let files = try?
            FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: [])
            else {
                return;
            }
        
        for file in files {
            let filename = file.lastPathComponent
            
            if filename.hasSuffix(".thumb"){
                let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                memories.append(memoryPath)
            }
        }
    }
    
    func addMemory(){
        let viewController = UIImagePickerController()
        
        viewController.modalPresentationStyle = .formSheet
        
        viewController.delegate = self
        
        navigationController?.present(viewController, animated: true)
        
    }
        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        if let possibleImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            //save new memory
            saveMemory(image: possibleImage)
            loadMemories()
        }
        
        dismiss(animated: true)
    }

    func saveMemory(image: UIImage){
    
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        
        let imageName = memoryName + ".jpg"
        
        let thumbnailName = memoryName + ".thumb"
        
        do {
            
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            
            if let jpegData = UIImageJPEGRepresentation(image, 80) {
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            
            if let thumbnail = resize(image: image, to: 200){
                
                let thumbPath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
                
                if let thumbData = UIImageJPEGRepresentation(thumbnail, 80){
                    try thumbData.write(to: thumbPath, options: [.atomicWrite])
                }
            }
            
        } catch {
            print("Erro ao salvar arquivo no disco")
        }
    }
    
    func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        
        let scale = width / image.size.width
        
        let height = image.size.height * scale
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height),false, 0)
        
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(section == 0) {
            return 0
        } else {
            return memories.count
        }
    }
}
