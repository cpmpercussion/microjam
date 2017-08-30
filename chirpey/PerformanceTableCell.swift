//
//  PerformanceTableCell.swift
//  microjam
//
//  Created by Charles Martin on 28/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

import UIKit

class PerformanceTableCell: UITableViewCell {
    
    var player: Player?
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var chirpContainer: UIView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var performer: UILabel!
    @IBOutlet weak var instrument: UILabel!
    @IBOutlet weak var context: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var replyButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        avatarImageView.backgroundColor = .lightGray
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
        avatarImageView.clipsToBounds = true
        
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
