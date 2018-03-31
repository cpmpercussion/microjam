//
//  MicrojamTutorialTestingScreenController.swift
//  microjam
//
//  Created by Charles Martin on 30/3/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

class MicrojamTutorialTestingScreenController: UIViewController {
    
    @IBOutlet weak var chirpViewContainer: UIView!
    
    var recorder: ChirpRecorder?

    override func viewDidLoad() {
        super.viewDidLoad()
        // configuration for the chirpViewContainer
        // Loaded with a new recorder. (i.e., in the jam tab)
        recorder = ChirpRecorder(frame: chirpViewContainer.bounds)
        recorder?.recordingView = ChirpRecordingView(frame: chirpViewContainer.bounds)
        if let recView = recorder?.recordingView {
            chirpViewContainer.addSubview(recView)
            recView.recordingColour = UIColor.blue.cgColor
        }
        chirpViewContainer.layer.cornerRadius = 8
        chirpViewContainer.layer.borderWidth = 1
        chirpViewContainer.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        chirpViewContainer.clipsToBounds = true
        chirpViewContainer.contentMode = .scaleAspectFill
        chirpViewContainer.backgroundColor = UIColor.red.darkerColor
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func skipTutorial(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }

}
