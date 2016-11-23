//
//  ViewController.swift
//  chirpey
//
//  Created by Charles Martin on 22/11/16.
//  Copyright © 2016 Charles Martin. All rights reserved.
//
import UIKit

class ViewController: UIViewController, PdReceiverDelegate {
    let SOUND_OUTPUT_CHANNELS = 2
    let SAMPLE_RATE = 44100
    let TICKS_PER_BUFFER = 4
    let PATCH_NAME = "chirp.pd"
    
    var audioController : PdAudioController?
    var openFile : PdFile?
    var progress = 0.0
    var progressTimer : Timer?
    
    @IBOutlet weak var chirpeySquare: ChirpView!
    @IBOutlet weak var recordingProgress: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        #if TARGET_IPHONE_SIMULATOR
            // where are you?
            NSLog("Documents Directory: %@", FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask).lastObject())
        #endif

        self.startAudioEngine()
        self.recordingProgress!.progress = 0.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK:  Regular Functions
    func startAudioEngine() {
        NSLog("VC: Starting Audio Engine");
        self.audioController = PdAudioController()
        self.audioController?.configurePlayback(withSampleRate: Int32(SAMPLE_RATE), numberChannels: Int32(SOUND_OUTPUT_CHANNELS), inputEnabled: false, mixingEnabled: true)
        self.audioController?.configureTicksPerBuffer(Int32(TICKS_PER_BUFFER))
        //    [self openPdPatch];
        PdBase.setDelegate(self)
        PdBase.subscribe("toGUI")
        PdBase.openFile(PATCH_NAME, path: Bundle.main.bundlePath)
        self.audioController?.isActive = true
        //[self.audioController setActive:YES];
        self.audioController?.print()
        NSLog("VC: Ticks Per Buffer: %d",self.audioController?.ticksPerBuffer ?? "didn't work!");
    }
    
    // MARK: Pd Send/Receive Methods
    func receivePrint(_ message: String!) {
        NSLog("Pd: %@", message)
    }

    // MARK: - Progress Bar and Timer
    func startTimer() {
        NSLog("Starting the timer")
        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: self.updateProgressView)
        self.chirpeySquare?.recording = true
    }
    
    func stopTimer() {
        self.progressTimer?.invalidate()
        self.progress = 0.0
        self.recordingProgress?.progress = 0.0
        NSLog("Timer stopped")
        let record = self.chirpeySquare?.reset()
        let recordingString = self.createCSVFromOrderedSet(set: record!);
        self.writeCSVToFile(csvString: recordingString)
        self.chirpeySquare?.playback(recording: record!)
    }
    
    func updateProgressView(_ : Timer) {
        self.progress += 0.01;
        self.recordingProgress?.progress = Float(self.progress / 5.0)
        if (self.progress >= 5.0) {self.stopTimer()}
    }
    
    // MARK: - Data Processing Methods
    // FIXME: This is really dodgy, the ordered set probably isn't very swift here.
    func createCSVFromOrderedSet(set : NSMutableOrderedSet) -> String {
        var output = "time,x,y,z,moving\n"
        for item in set.array as! [[NSNumber]] {
            let line = String(format:"%f, %f, %f, %f,%d\n", item[0], item[1], item[2], item[3], item[4])
            output.append(line)
        }
        return output
    }
    
//    - (NSString *) createCSVFromOrderedSet:(NSMutableOrderedSet *) set
//    {
//    NSString *output = @"time,x,y,z,moving\n";
//    for (NSArray *item in set) {
//    NSString *line = [NSString stringWithFormat:@"%f, %f, %f, %f,%d\n", ((NSNumber *) item[0]).floatValue, ((NSNumber *) item[1]).floatValue, ((NSNumber *) item[2]).floatValue, ((NSNumber *) item[3]).floatValue,((NSNumber *) item[4]).intValue];
//    output = [output stringByAppendingString:line];
//    }
//    //output = [output stringByAppendingString:@" \n "];
//    return output;
//    }
    
    /**
     Writes a string to the documents directory with a title formed from the current date.
    **/
    func writeCSVToFile(csvString : String) {
        var filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-DD-HH-mm-SS"
        let dateString = formatter.string(from: Date());
        filePath.append(String(format: "chirprec-%@", dateString))
        try! csvString.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
    }
    
    // MARK: - Touch methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // start timer if not recording
        let p = touches.first?.location(in: self.chirpeySquare);
        if (self.chirpeySquare!.bounds.contains(p!) && !self.chirpeySquare!.recording) {
                self.startTimer()
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
