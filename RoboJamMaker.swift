//
//  RoboJamMaker.swift
//  microjam
//
//  Created by Charles Martin on 8/11/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

let roboResponseEndpoint: String = "https://138.197.179.234:5000/api/predict"
// let roboResponseEndpoint: String = "https://0.0.0.0:5000/api/predict" // for local testing.

class RobojamMaker: NSObject {
    
    /// Set up a robojam request from a particular performance to a particular ChirpJamViewController
    static func requestRobojam(from perf: ChirpPerformance, for chirpController: ChirpJamViewController) {
        
        let perfToRespond = perf.csv() // get a CSV version of the call performance
        
        // print("found performance: \(perfToRespond)")
        guard let roboResponseURL = URL(string: roboResponseEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        // print("have URL: \(roboResponseURL)")
        
        var roboResponseUrlRequest = URLRequest(url: roboResponseURL)
        roboResponseUrlRequest.httpMethod = "POST"
        
        let perfRequest: [String: Any] = ["perf": perfToRespond]
        let jsonPerfRequest: Data
        do {
            jsonPerfRequest = try JSONSerialization.data(withJSONObject: perfRequest, options: [])
            roboResponseUrlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            roboResponseUrlRequest.httpBody = jsonPerfRequest
        } catch {
            print("Error: cannot create JSON")
            return
        }
        
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: RobojamCertificatePinningDelegate(), delegateQueue: nil)
        let task = session.dataTask(with: roboResponseUrlRequest) { data, response, error in
            // do stuff with response, data & error here
            DispatchQueue.main.async{
                chirpController.robojamFailed() // first stop the bopping.
            }
            guard error == nil else {
                print("error calling POST on /api/predict")
                print(error!)
                return
            }
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // parse the result as JSON, since that's what the API provides
            RobojamMaker.robojamResponseHandler(responseData, jamViewController: chirpController)
        }
        task.resume()
        
    }
    
    /// Parses Responses from the Robojam server.
    static func robojamResponseHandler(_ data: Data, jamViewController: ChirpJamViewController) {
        print("Robojam: Parsing response.")
        do {
            guard let responsePerfJSON = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any] else {
                    print("error trying to convert data to JSON")
                    return
            }
            // print("The response is: " + responsePerfJSON.description)
            guard let responsePerfCSV = responsePerfJSON["response"] as? String else {
                print("Could not parse JSON")
                return
            }
            // print("Response found!")
            // print("The response was: " + responsePerfCSV)
            if let responsePerf = createRobojam(responsePerfCSV) {
                DispatchQueue.main.async{
                    jamViewController.addRobojam(responsePerf)
                }
            }
            // do something with it.
        } catch  {
            print("error trying to convert data to JSON")
            return
        }
    }
    

    
    /// Transform a RoboJam response into ChirpPerformance for playback.
    static func createRobojam(_ perfCSV: String) -> ChirpPerformance? {
        let instrument = chooseRandomInstrument()
        return ChirpPerformance(csv: perfCSV, date: Date(), performer: RoboJamPerfData.performer, instrument: instrument, image: UIImage(), location: RoboJamPerfData.fakeLocation, colour: RoboJamPerfData.color, background: RoboJamPerfData.bg, replyto: "", performanceID: RoboJamPerfData.id, creatorID: RoboJamPerfData.creator)
    }
    
    static func chooseOtherInstrument(_ inst: String) -> String {
        let instChoices = SoundSchemes.keysForNames.keys.filter { $0 != inst } as [String]
        let choice = instChoices[Int(arc4random_uniform(UInt32(instChoices.count)))]
        print("RoboJam is playing: \(choice)")
        return choice
    }
    
    static func chooseRandomInstrument() -> String {
        let instChoices = Array(SoundSchemes.keysForNames.keys)
        let choice = instChoices[Int(arc4random_uniform(UInt32(instChoices.count)))]
        return choice
    }

}

// MARK: - Robojam HTTPS Certificate Pinning URLSession delegate
// adapted from lifeisfoo https://stackoverflow.com/a/34223292/1646138
class RobojamCertificatePinningDelegate: NSObject, URLSessionDelegate {
    
    /// Robojam server certificate file
    private let robojamCertificateFile = "robojamCertificate"
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        // Adapted from OWASP https://www.owasp.org/index.php/Certificate_and_Public_Key_Pinning#iOS
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust),
            let serverTrust = challenge.protectionSpace.serverTrust {
            var secresult = SecTrustResultType.invalid
            let status = SecTrustEvaluate(serverTrust, &secresult)
            
            if (errSecSuccess == status), let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                let serverCertificateData = SecCertificateCopyData(serverCertificate)
                let data = CFDataGetBytePtr(serverCertificateData);
                let size = CFDataGetLength(serverCertificateData);
                let cert1 = NSData(bytes: data, length: size)
                let file_der = Bundle.main.path(forResource: robojamCertificateFile, ofType: "der")
                
                if let file = file_der, let cert2 = NSData(contentsOfFile: file), cert1.isEqual(to: cert2 as Data) {
                    completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust:serverTrust))
                    return
                }
            }
        }
        // Pinning failed
        completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
    }
    
}
