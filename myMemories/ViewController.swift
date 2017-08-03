//
//  ViewController.swift
//  myMemories
//
//  Created by Adriano Ronszcka on 27/07/17.
//  Copyright © 2017 Adriano Ronszcka. All rights reserved.
//

import UIKit

import AVFoundation
import Photos
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var permissionsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func requestPhotoPermissions() {
        
        PHPhotoLibrary.requestAuthorization { [unowned self]
            
            authStatus in
            
            DispatchQueue.main.async {
                
                if authStatus == .authorized {
                    
                    //self.req...
                    
                } else {
                    
                    self.permissionsLabel.text = "As permissões para acessar as fotos foram negadas, por favor ative as permissões nas Configurações do seu iPhone."
                    
                }
                
            }
            
        }
        
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func requestPermissions(_ sender: Any) {
        
    }

}

