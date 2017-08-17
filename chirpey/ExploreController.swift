//
//  ExploreController.swift
//  microjam
//
//  Created by Henrik Brustad on 17/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit
import CloudKit

private let cellIdentifier = "exploreCell"

class ExploreController: UIViewController {
    
    /// Local reference to the performanceStore singleton.
    let performanceStore = (UIApplication.shared.delegate as! AppDelegate).performanceStore
    /// Global ID for wordJamCells.
    //let worldJamCellIdentifier = "worldJamCell"
    /// Local dictionary relating CKRecordIDs (Of Users records) to PerformerProfile objects.
    var localProfileStore = [CKRecordID: PerformerProfile]()
    /// Local reference to the PerformerProfileStore
    let profilesStore = PerformerProfileStore.shared
    
    let performanceHandler = PerformanceHandler()
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.backgroundColor = .white
        cv.register(ExploreCell.self, forCellWithReuseIdentifier: cellIdentifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "World Jams"
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        performanceStore.delegate = self
        profilesStore.delegate = self
        
        initSubview()
    }
    
    private func initSubview() {
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    }
    
    /// Loads a string crediting the original performer
    func creditString(originalPerformer: String) -> String {
        let output = "replied to " + originalPerformer
        return output
    }
    
    /// Loads a credit string for a solo performance
    func nonCreditString() -> String {
        let ind : Int = Int(arc4random_uniform(UInt32(PerformanceLabels.solo.count)))
        return PerformanceLabels.solo[ind]
    }
    
    /// Adds multiple images on top of each other
    func createImageFrom(images : [UIImage]) -> UIImage? {
        if let size = images.first?.size {
            UIGraphicsBeginImageContext(size)
            let areaSize = CGRect(x: 0, y: 0, width:size.width, height: size.height)
            for image in images.reversed() {
                image.draw(in: areaSize, blendMode: CGBlendMode.normal, alpha: 1.0)
            }
            let outImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return outImage
        }
        return nil
    }
    
    func playButtonPressed() {
        print("Play button pressed")
        
        let index = Int(collectionView.contentOffset.x / view.frame.width)
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as! ExploreCell
        
        if !performanceHandler.isPlaying {
            
            var performances = [ChirpPerformance]()
            
            var selectedJam = performanceStore.storedPerformances[index]
            performances.append(selectedJam)
            
            while selectedJam.replyto != "" {
                
                if let reply = performanceStore.fetchPerformanceFrom(title: selectedJam.replyto) {
                    performances.append(reply)
                    selectedJam = reply
                    print("WJTVC: cued a reply")
                } else {
                    break // if a reply can't be found, stop loading the thread.
                }
            }
            
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { (_) in
                self.performanceHandler.stopPerformances()
                cell.playButton.setTitle("Play", for: .normal)
            })
            
            performanceHandler.play(performances: performances)
            
            cell.playButton.setTitle("Stop", for: .normal)
        
        } else {
            performanceHandler.stopPerformances()
            cell.playButton.setTitle("Play", for: .normal)
        }
    }
    
    func replyButtonPressed() {
        print("Reply button pressed")
        
        let index = Int(collectionView.contentOffset.x / view.frame.width)
        print(index)
        
        // Show the performance in a new ChirpJamController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "chirpJamController") as! ChirpJamViewController
        controller.newViewWith(performance: performanceStore.storedPerformances[index], withFrame: nil)
        
        var selectedJam = performanceStore.storedPerformances[index]
        
        while selectedJam.replyto != "" { // load up all replies.
            // FIXME: fetching replies fails if they have not been downloaded from cloud.
            if let reply = performanceStore.fetchPerformanceFrom(title: selectedJam.replyto) {
                controller.newViewWith(performance: reply, withFrame: nil)
                selectedJam = reply
                print("WJTVC: cued a reply")
            } else {
                break // if a reply can't be found, stop loading the thread.
            }
        }
        
        // Present the chirpViewController
        navigationController?.pushViewController(controller, animated: true)
    }
    
}

extension ExploreController: UICollectionViewDelegate {
    
}

extension ExploreController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return performanceStore.storedPerformances.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ExploreCell
        
        let performance = performanceStore.storedPerformances[indexPath.item]
        
        if let profile = profilesStore.getProfile(forPerformance: performance) {
            cell.avatarImageView.image = profile.avatar
        }
        
        cell.title.text = performance.dateString
        cell.performer.text = performance.performer
        cell.instrument.text = performance.instrument
        cell.playButton.addTarget(self, action: #selector(playButtonPressed), for: .touchUpInside)
        cell.replyButton.addTarget(self, action: #selector(replyButtonPressed), for: .touchUpInside)
        
        cell.previewImage.image = performance.image
        cell.context.text = nonCreditString()
        
        var temp = performance // used to store replies as we fetch them.
        var images = [performance.image] // the stack of reply images.
        
        // Get the image from every reply
        while temp.replyto != "" {
            if let replyPerf = performanceStore.fetchPerformanceFrom(title: temp.replyto) {
                cell.context.text = creditString(originalPerformer: replyPerf.performer)
                images.append(replyPerf.image)
                temp = replyPerf
            } else {
                // break if the replyPerf can't be found.
                // TODO: in this case, the performance should be fetched from the cloud. but there isn't functionality in the store for this yet.
                break
            }
            print("WJTVC: loaded a reply.")
        }
        
        // Sum all the images into one and display
        cell.previewImage.image = createImageFrom(images: images)
        
        return cell
    }
    
}

extension ExploreController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height - 64 - 49)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - ModelDelegate methods

extension ExploreController: ModelDelegate {
    
    /// Conforms to ModelDelegate Protocol
    func modelUpdated() {
        print("WJTVC: Model updated, reloading data")
        //refreshControl?.endRefreshing()
        collectionView.reloadData()
    }
    
    /// Conforms to ModelDelegate Protocol
    func errorUpdating(error: NSError) {
        let message: String
        if error.code == 1 {
            message = "Log into iCloud on your device and make sure the iCloud drive is turned on for this app."
        } else {
            message = error.localizedDescription
        }
        let alertController = UIAlertController(title: nil,
                                                message: message,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
}






















