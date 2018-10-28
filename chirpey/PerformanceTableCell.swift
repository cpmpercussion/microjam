//
//  PerformanceTableCell.swift
//  microjam
//
//  Created by Charles Martin on 28/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//

import UIKit

class PerformanceTableCell: UITableViewCell {
    
    /// A player controller for the ChirpView in the present cell
    var player: ChirpPlayer?
    /// The avatar image in the cell
    @IBOutlet weak var avatarImageView: UIImageView!
    /// Container view for the one or more ChirpViews for the cell
    @IBOutlet weak var chirpContainer: UIView!
    /// Title of the top performance in the cell
    @IBOutlet weak var title: UILabel!
    /// Performer of the top performance in the cell
    @IBOutlet weak var performer: UILabel!
    /// Instrument of the top performance in the cell
    @IBOutlet weak var instrument: UILabel!
    /// A context  label describing added details about the performance
    @IBOutlet weak var context: UILabel!
    /// A play button layered over the ChirpContainer
    @IBOutlet weak var playButton: UIButton!
    /// A reply button layered over the ChirpContainer
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
        
        setColourTheme()
    }
    
    /// Updates UI with data from a given PerformerProfile
    func display(performerProfile profile: PerformerProfile) {
        avatarImageView.image = #imageLiteral(resourceName: "empty-profile-image")
        avatarImageView.image = profile.avatar
        performer.text = profile.stageName
    }
    
    /// Infers correct PerformerProfile from the ChirpPlayer and gets appropriate profile.
    func displayProfileFromPlayer() {
        if let perf = player?.chirpViews.first?.performance,
            let profile = PerformerProfileStore.shared.getProfile(forPerformance: perf) {
            print("Successfully updated profile for: \(profile.stageName) in a PerformanceTableCell")
            //PerformerProfileStore.shared.getProfile(forID: perfID) {
            self.display(performerProfile: profile)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    /// Prepare the cell for reuse by closing all Pd files.
    override func prepareForReuse() {
        /// Close ChirpViews in the cell's player (if they exist)
        if let player = player {
            // Stop Playing
            player.stop()
            // Close Pd Files
            for chirp in player.chirpViews {
                chirp.closePdFile()
                chirp.removeFromSuperview()
            }
        }
    }

}

// Set up dark and light mode.
extension PerformanceTableCell {
    
    func setColourTheme() {
        setDarkMode()
    }
    
    func setDarkMode() {
        backgroundColor = DarkMode.background
        //avatarImageView //: UIImageView!
        chirpContainer.backgroundColor = DarkMode.midbackground//: UIView!
        title.textColor = DarkMode.text //: UILabel!
        performer.textColor = DarkMode.text //: UILabel!
        instrument.textColor = DarkMode.text //: UILabel!
        context.textColor = DarkMode.text //: UILabel!
        //playButton // : UIButton!
        //replyButton //: UIButton!
    }
    
    func setLightMode() {
        backgroundColor = LightMode.background
        //avatarImageView //: UIImageView!
        chirpContainer.backgroundColor = LightMode.midbackground//: UIView!
        title.textColor = LightMode.text //: UILabel!
        performer.textColor = LightMode.text //: UILabel!
        instrument.textColor = LightMode.text //: UILabel!
        context.textColor = LightMode.text //: UILabel!
        //playButton // : UIButton!
        //replyButton //: UIButton!
    }
}

