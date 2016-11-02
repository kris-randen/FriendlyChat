//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Photos
import UIKit

import Firebase
import GoogleMobileAds

/**
 * AdMob ad unit IDs are not currently stored inside the google-services.plist file. Developers
 * using AdMob can store them as custom values in another plist, or simply use constants. Note that
 * these ad units are configured to return only test ads, and should not be used outside this sample.
 */
let kBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"

@objc(FCViewController)
class FCViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
    UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // Instance variables
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    var ref: FIRDatabaseReference!
    var messages: [FIRDataSnapshot]! = []
    var msglength: NSNumber = 10
    fileprivate var _refHandle: FIRDatabaseHandle!

    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!

    @IBOutlet weak var banner: GADBannerView!
    @IBOutlet weak var clientTable: UITableView!


    override func viewDidLoad()
    {
        super.viewDidLoad()

        clientTable.delegate = self
        clientTable.dataSource = self

        configureDatabase()
        configureStorage()
        configureRemoteConfig()
        fetchConfig()
        loadAd()
        logViewLoaded()
    }

    deinit
    {
        self.ref.child(Constants.Database.messages).removeObserver(withHandle: _refHandle)
    }

    func configureDatabase()
    {
        ref = FIRDatabase.database().reference()
        // Listen for new messages in the Firebase database
        
        _refHandle = self.ref.child(Constants.Database.messages).observe(.childAdded, with:
        { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else { return }
            strongSelf.messages.append(snapshot)
            strongSelf.clientTable.insertRows(at: [IndexPath(row: strongSelf.messages.count-1, section: 0)], with: .automatic)
        })
    }

    func configureStorage()
    {
        let storageURL  = FIRApp.defaultApp()?.options.storageBucket
        storageRef = FIRStorage.storage().reference(forURL: Constants.Storage.urlPrefix + storageURL!)
    }

    func configureRemoteConfig()
    {
        
    }

    func fetchConfig()
    {
        
    }

    @IBAction func didPressFreshConfig(_ sender: AnyObject)
    {
        fetchConfig()
    }

    @IBAction func didSendMessage(_ sender: UIButton)
    {
        textFieldShouldReturn(textField)
    }

    @IBAction func didPressCrash(_ sender: AnyObject)
    {
        fatalError()
    }

    func logViewLoaded()
    {
        
    }

    func loadAd()
    {
        
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        guard let text = textField.text else { return true }

        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= self.msglength.intValue // Bool
    }

    // UITableViewDataSource protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {   // Dequeue cell
        if let cell = clientTable.dequeueReusableCell(withIdentifier: Constants.ClientCell.Identifier, for: indexPath) as? ClientCell
        {
            // Unpack message from Firebase DataSnapshot
            let messageSnapshot: FIRDataSnapshot! = self.messages[indexPath.row]
            let message = messageSnapshot.value as! [String : String]
            cell.updateUI(withMessage: message)
            return cell
        }
        else
        {
            return ClientCell()
        }
    }

    // UITextViewDelegate protocol methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        guard let text = textField.text else { return true }
        let data = [Constants.MessageFields.text: text]
        sendMessage(withData: data)
        return true
    }

    func sendMessage(withData data: [String: String])
    {
        var mdata = data
        mdata[Constants.MessageFields.name] = AppState.sharedInstance.displayName
        if let photoURL = AppState.sharedInstance.photoURL
        {
            mdata[Constants.MessageFields.photoURL] = photoURL.absoluteString
        }
        // Push data to Firebase Database
        self.ref.child(Constants.Database.messages).childByAutoId().setValue(mdata)
    }

    // MARK: - Image Picker

    @IBAction func didTapAddPhoto(_ sender: AnyObject)
    {
        let picker = UIImagePickerController()
        picker.delegate = self
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera))
        {
            picker.sourceType = UIImagePickerControllerSourceType.camera
        }
        else
        {
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        }

        present(picker, animated: true, completion:nil)
    }

    func imagePickerController(_ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [String : Any])
    {
          picker.dismiss(animated: true, completion:nil)
        guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }

        // if it's a photo from the library, not an image from the camera
//        if #available(iOS 8.0, *), let referenceURL = info[UIImagePickerControllerReferenceURL]
//        {
//            let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceURL as! URL], options: nil)
//            let asset = assets.firstObject
//            asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
//            let imageFile = contentEditingInput?.fullSizeImageURL
//            let filePath = "\(uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\((referenceURL as AnyObject).lastPathComponent!)"
//            })
//        }
//        else
//        {
        guard let image = info[UIImagePickerControllerOriginalImage] as! UIImage? else { return }
        let imageData = UIImageJPEGRepresentation(image, 0.8)
        let imagePath = "\(uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        let metadata = FIRStorageMetadata()
        metadata.contentType = Constants.Storage.contentTypeJPEG
        self.storageRef.child(imagePath).put(imageData!, metadata: metadata)
        { [weak self] (metadata, error) in
            
            if let error = error
            {
                print("Error uploading image: \(error)")
                return
            }
            guard let strongSelf = self else { return }
            strongSelf.sendMessage(withData: [Constants.MessageFields.imageURL : strongSelf.storageRef.child((metadata?.path)!).description])
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion:nil)
    }

    @IBAction func signOut(_ sender: UIButton)
    {
        let firebaseAuth = FIRAuth.auth()
        do
        {
            try firebaseAuth?.signOut()
            AppState.sharedInstance.signedIn = false
            dismiss(animated: true, completion: nil)
        }
        catch let signOutError as NSError
        {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }

    func showAlert(withTitle title:String, message:String)
    {
        DispatchQueue.main.async
        {
            let alert = UIAlertController(title: title,
                message: message, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
