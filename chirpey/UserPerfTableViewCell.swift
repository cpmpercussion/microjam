//
//  UserPerfTableViewCell.swift
//  microjam
//
//  Created by Charles Martin on 1/5/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

class UserPerfTableViewCell: UITableViewCell {
    
    /// A player controller for the ChirpView in the present cell
    var player: ChirpPlayer?
    /// Container view for the one or more ChirpViews for the cell
    @IBOutlet weak var chirpContainer: UIView!
    /// A play button layered over the ChirpContainer
    @IBOutlet weak var playButton: UIButton!
    /// A reply button layered over the ChirpContainer
    @IBOutlet weak var replyButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        chirpContainer.layer.cornerRadius = 8
        chirpContainer.layer.borderWidth = 1
        chirpContainer.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        chirpContainer.backgroundColor = .white
        chirpContainer.clipsToBounds = true
        
        playButton.layer.cornerRadius = 18 // Button size is 36
        playButton.setImage(#imageLiteral(resourceName: "microjam-play"), for: .normal)
        playButton.tintColor = UIColor.darkGray
        
        replyButton.layer.cornerRadius = 18 // Button size is 36
        replyButton.setImage(#imageLiteral(resourceName: "microjam-reply"), for: .normal)
        replyButton.tintColor = UIColor.darkGray
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
