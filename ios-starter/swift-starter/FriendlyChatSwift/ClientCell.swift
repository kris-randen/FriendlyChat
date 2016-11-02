//
//  ClientCell.swift
//  FriendlyChatSwift
//
//  Created by Kris Rajendren on Nov/2/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit
import Firebase

class ClientCell: UITableViewCell {

    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func updateUI(withMessage message: [String : String])
    {
        let name = message[Constants.MessageFields.name] as String!
        if let imageURL = message[Constants.MessageFields.imageURL]
        {
            if imageURL.hasPrefix(Constants.Storage.urlPrefix)
            {
                FIRStorage.storage().reference(forURL: imageURL).data(withMaxSize: INT64_MAX)
                { (data, error) in
                    if let error = error
                    {
                        print("Error downloading image: \(error)")
                        return
                    }
                    self.postImage.image = UIImage(data: data!)
                }
            }
            else if let URL = URL(string: imageURL),
                    let data = try? Data(contentsOf: URL)
            {
                self.postImage.image = UIImage(data: data)
            }
            postText.text = "sent by: \(name!)"
        }
        else
        {
            let text = message[Constants.MessageFields.text] as String!
            postText.text = name! + ": " + text!
            postImage.contentMode = .scaleAspectFit
            postImage.image = UIImage(named: "100")
            if let photoURL = message[Constants.MessageFields.photoURL],
            let URL = URL(string: photoURL),
            let data = try? Data(contentsOf: URL)
            {
                postImage.image = UIImage(data: data)
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
