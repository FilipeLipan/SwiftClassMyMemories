import UIKit

import AVFoundation
import Photos
import Speech
import CoreSpotlight
import MobileCoreServices

class MemoriesViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, AVAudioRecorderDelegate {
    
    var memories = [URL]()
    var filteredMemories = [URL]()
    var activeMemory: URL!
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL!
    var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMemory))
        
        recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        loadMemories()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let possibleImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            saveNewMemory(image: possibleImage)
            loadMemories()
        }
        dismiss(animated: true)
    }
    
    func saveNewMemory(image: UIImage){
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        let imageName = memoryName + ".jpg"
        let thumbnailName = memoryName + ".thumb"
        do {
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            if let jpegData = UIImageJPEGRepresentation(image, 80){
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            if let thumbnail = resize(image: image, to: 200){
                let thumbPath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
                if let thumbData = UIImageJPEGRepresentation(thumbnail, 80){
                    try thumbData.write(to: thumbPath, options: [.atomicWrite])
                }
            }
        } catch {
            print("erro ao salvar no disco")
        }
    }
    
    func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        let scale = width / image.size.width
        let height = image.size.height * scale
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func addMemory() {
        let viewController = UIImagePickerController()
        viewController.modalPresentationStyle = .formSheet
        viewController.delegate = self
        navigationController?.present(viewController, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkPermissions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
        let memory = filteredMemories[indexPath.row]
        let imageName = memory.appendingPathExtension("thumb").path
        let image = UIImage.init(named: imageName)
        cell.imageView.image = image
        if cell.gestureRecognizers == nil{
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(memoryLongPress))
            recognizer.minimumPressDuration = 0.25
            cell.addGestureRecognizer(recognizer)
            
            
            /*let rec = UILongPressGestureRecognizer(target: self, action: #selector(teste))
            rec.minimumPressDuration = 0.50
            cell.addGestureRecognizer(rec)*/
        }
        
        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.borderWidth = 3
        cell.layer.cornerRadius = 10
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
    }
    
    func checkPermissions() {
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let authorized = photosAuthorized && recordingAuthorized && transcribeAuthorized
        
        if authorized == false {
            if let permissionsViewController = storyboard?.instantiateViewController(withIdentifier: "Permission"){
                navigationController?.present(permissionsViewController, animated: true)
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func loadMemories() {
        memories.removeAll()
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: [])
            else {
                return;
        }
        for file in files {
            let filename = file.lastPathComponent
            if filename.hasSuffix(".thumb") {
                let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                memories.append(memoryPath)
            }
        }
        filteredMemories = memories
        collectionView?.reloadSections(IndexSet(integer: 1))
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        } else {
            return filteredMemories.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize.zero
        } else {
            return CGSize(width: 0, height: 50)
        }
    }
    
    func memoryLongPress(sender: UILongPressGestureRecognizer){
        if sender.state == .began {
            collectionView?.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1.0)
            let cell = sender.view as! MemoryCell
            if let index = collectionView?.indexPath(for: cell){
                activeMemory = filteredMemories[index.row]
                recordMemory()
            }
        } else if sender.state == .ended {
            finishRecording(sucess: true)
        }
    }
    
    func recordMemory(){
        let recordingSession = AVAudioSession.sharedInstance()
        do{
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44100, AVNumberOfChannelsKey: 2, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        }catch let error {
            print("erro ao gravar audio:  \(error)")
            finishRecording(sucess: false)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(sucess: false)
        }
    }
    
    func finishRecording(sucess: Bool){
        collectionView?.backgroundColor = UIColor.darkGray
        audioRecorder?.stop()
        if sucess {
            do{
                let memoryAudioURL = activeMemory.appendingPathExtension("m4a")
                let fileManager  = FileManager.default
                if fileManager.fileExists(atPath: memoryAudioURL.path){
                    try fileManager.removeItem(at: memoryAudioURL)
                }
                try fileManager.moveItem(at: recordingURL, to: memoryAudioURL)
                transcribeAudio(memory: memoryAudioURL)
            } catch let error {
                print("falha ao gravar audio:  \(error)")
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = filteredMemories[indexPath.row]
        let fileManager = FileManager.default
        
        do{
            let audioName = audrioURL(for: memory)
            if fileManager.fileExists(atPath: audioName.path) {
                audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                audioPlayer?.play()
            }
        } catch let error {
            print("falha ao reproduzir audio:  \(error)")
        }
    }
    
    func transcribeAudio(memory: URL) {
        let audio = memory//.appendingPathExtension("m4a")
        let transcription = memory.appendingPathExtension("txt")
        let recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "pt-BR"))
        let request = SFSpeechURLRecognitionRequest(url: audio)
        recognizer?.recognitionTask(with: request){
            (result, error) in
            guard let result = result else {
                print("Erro ao transcrever:  \(String(describing: error))")
                return
            }
            
            if result.isFinal {
                let text = result.bestTranscription.formattedString
                
                do {
                    print(text)
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                } catch let error {
                    print("falha ao salvar transcricao de audio:  \(error)")
                }
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterMemories(text: searchText)
    }
    
    func searchBarSearchButton(_ searchBar: UISearchBar){
        searchBar.resignFirstResponder()
    }
    
    func filterMemories(text: String){
        guard text.characters.count > 0 else {
            filteredMemories = memories
            UIView.performWithoutAnimation {
                collectionView?.reloadSections(IndexSet(integer: 1))
            }
            return
        }
        
        var allItems = [CSSearchableItem]()
        var searchQuery: CSSearchQuery?
        let queryString = "contentsDescription == \"*\(text)*\"c"
        searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
        searchQuery?.foundItemsHandler = { items in allItems.append(contentsOf: items) }
        searchQuery?.completionHandler = { error in DispatchQueue.main.async {
            [unowned self] in
            self.activateFilter(matches: allItems)
            } }
        searchQuery?.start()
    }
    
    func activateFilter(matches: [CSSearchableItem]){
        filteredMemories = matches.map{
            item in
            return URL(fileURLWithPath: item.uniqueIdentifier)
        }
        UIView.performWithoutAnimation {
            collectionView?.reloadSections(IndexSet(integer: 1))
        }
    }
    
    func audrioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }
    
    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    
    /*func teste(sender: UILongPressGestureRecognizer){
     if sender.state == .began {
     collectionView?.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
     }
    }*/
    
}




