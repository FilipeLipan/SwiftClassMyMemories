import UIKit

import AVFoundation
import Photos
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var permissionLabel: UILabel!
    
    @IBAction func requestPermission(_ sender: Any) {
        requestPhotosPermission()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func requestPhotosPermission() {
        PHPhotoLibrary.requestAuthorization {[unowned self]
        authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.requestRecordPermission()
                } else {
                    self.permissionLabel.text = "As permissoes para acessar as fotos foram negadas, por favor ative as permissoes nas Configuracoes do seu iPhone...."
                }
            }
        }
    }
    
    func requestRecordPermission(){
        AVAudioSession.sharedInstance().requestRecordPermission {[unowned self]
            allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.requestTranscribePermission()
                } else {
                    self.permissionLabel.text = "As permissoes para gravacao de audio foram negadas, por favor ative as permissoes nas Configuracoes do seu iPhone...."
                }
            }
        }
    }
    
    func requestTranscribePermission(){
        SFSpeechRecognizer.requestAuthorization {[unowned self]
            authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizathionComplete()
                } else {
                    self.permissionLabel.text = "As permissoes para transcricao de audio foram negadas, por favor ative as permissoes nas Configuracoes do seu iPhone...."
                }
            }
        }
    }
    
    func authorizathionComplete() {
        dismiss(animated: true)
    }
}
