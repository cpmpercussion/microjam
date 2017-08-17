//
//  PerformanceViewHandler.swift
//  microjam
//
//  Created by Henrik Brustad on 16/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class PerformanceViewHandler: PerformanceHandler {
    
    var imageViews = [UIImageView]()
    
    // Used when added performances outside of the controller
    override func add(performance: ChirpPerformance) {
        super.add(performance: performance)
        let imageView = UIImageView(image: performance.image)
        imageView.isUserInteractionEnabled = false
        imageViews.append(imageView)
    }
    
    // Adding performance within the controller
    func add(performance: ChirpPerformance, inView view: UIView) {
        super.add(performance: performance)
        let imageView = UIImageView(frame: view.bounds)
        imageView.image = performance.image
        imageView.isUserInteractionEnabled = false
        imageViews.append(imageView)
        view.addSubview(imageView)
    }
    
    // Used mostly for recorded performances
    func add(performance: ChirpPerformance, withPdFile file: PdFile, andImageView view: UIImageView) {
        super.add(performance: performance, withPdFile: file)
        imageViews.append(view)
    }
    
    func remove(performance: ChirpPerformance, andImageView view: UIImageView) {
        super.remove(performance: performance)
        if let index = imageViews.index(of: view) {
            imageViews.remove(at: index)
        }
    }
    
    override func removeLastPerformance() {
        // Remove last performances, closing and removing pdFile
        super.removeLastPerformance()
        if let view = imageViews.popLast() {
            // Remove the last image view from the superview
            view.removeFromSuperview()
        }
    }
    
    // remove all performances
    override func removePerformances() {
        super.removePerformances()
        for view in imageViews {
            view.removeFromSuperview()
        }
        imageViews.removeAll()
    }
    
    // If performances are added outside of the controller, they need to be added to a parent view
    func displayImagesIn(view: UIView) {
        for iv in imageViews {
            iv.frame = view.bounds
            view.addSubview(iv)
        }
    }
    
    override func playPerformances() {
        
        isPlaying = true
        timers = [Timer]()
        
        for (i, perf) in performances.enumerated() {
            // make the timers
            var previousTouch: TouchRecord?
            for touch in perf.performanceData {
                timers!.append(Timer.scheduledTimer(withTimeInterval: touch.time, repeats: false, block: { _ in
                    // play back for each touch, with the performance instrument
                    self.makeSound(withTouch: touch, andPdFile: self.pdFiles[i])
                    self.draw(inImageView: self.imageViews[i], withTouch: touch, previousTouch: previousTouch, andColor: perf.colour.brighterColor.cgColor)
                    previousTouch = touch
                }))
            }
        }
    }
    
    func resetPerformanceImages() {
        for (i, view) in imageViews.enumerated() {
            view.image = performances[i].image
        }
    }
    
    func draw(inImageView imageView: UIImageView, withTouch current: TouchRecord, previousTouch previous: TouchRecord?, andColor color: CGColor) {
        
        let size = imageView.frame.width
        
        if current.moving {
            let previousPoint = CGPoint(x: CGFloat(previous!.x) * size, y: CGFloat(previous!.y) * size)
            let currentPoint = CGPoint(x: CGFloat(current.x) * size, y: CGFloat(current.y) * size)
            drawLine(inImageView: imageView, fromPoint: previousPoint, toPoint: currentPoint, withColor: color)
        } else {
            let currentPoint = CGPoint(x: CGFloat(current.x) * size, y: CGFloat(current.y) * size)
            drawDot(inImageView: imageView, atPoint: currentPoint, withColor: color)
        }
    }
    
    // MARK: - drawing functions
    
    /// Draws a dot at a given point in the UIImage.
    func drawDot(inImageView imageView: UIImageView, atPoint point: CGPoint, withColor color: CGColor) {
        UIGraphicsBeginImageContextWithOptions(imageView.frame.size, false, (UIScreen.main).scale)
        let context = UIGraphicsGetCurrentContext();
        imageView.image!.draw(in: imageView.bounds)
        context!.setFillColor(color);
        context!.setBlendMode(CGBlendMode.normal)
        context!.fillEllipse(in: CGRect(x:point.x - 5, y:point.y - 5, width:10, height:10));
        imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    /// Draws a line between two points in the UIImage.
    func drawLine(inImageView imageView: UIImageView, fromPoint from: CGPoint, toPoint to: CGPoint, withColor color: CGColor) {
        UIGraphicsBeginImageContextWithOptions(imageView.frame.size, false, (UIScreen.main).scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        imageView.image?.draw(in: imageView.bounds)
        context.move(to: from)
        context.addLine(to: to)
        context.setLineCap(CGLineCap.round)
        context.setLineWidth(10.0)
        context.setStrokeColor(color)
        context.setBlendMode(CGBlendMode.normal)
        context.strokePath()
        imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
}












