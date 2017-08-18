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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
