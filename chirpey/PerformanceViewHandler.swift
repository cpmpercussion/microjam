//
//  PerformanceViewHandler.swift
//  microjam
//
//  Created by Henrik Brustad on 16/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class PerformanceViewHandler: PerformanceHandler {
    
    var imageViews: [UIImageView]?
    
    override func add(performance: ChirpPerformance) {
        super.add(performance: performance)
        
        if imageViews == nil {
            imageViews = [UIImageView]()
        }
        
        imageViews!.append(UIImageView(image: performance.image))
    }
    
    func displayImagesIn(view: UIView) {
        
        if let views = imageViews {
            for v in views {
                v.frame = view.bounds
                view.addSubview(v)
            }
        }
    }
    
    override func playPerformances() {
        
        if let perfs = performances {
            isPlaying = true
            timers = [Timer]()
            for (i, perf) in perfs.enumerated() {
                // make the timers
                var previousTouch: TouchRecord?
                for touch in perf.performanceData {
                    timers!.append(Timer.scheduledTimer(withTimeInterval: touch.time, repeats: false, block: { _ in
                        // play back for each touch, with the performance instrument
                        self.makeSound(withTouch: touch, andPdFile: self.pdFiles![i])
                        self.draw(inImageView: self.imageViews![i], withTouch: touch, previousTouch: previousTouch, andColor: perf.colour.brighterColor.cgColor)
                    }))
                    previousTouch = touch
                }
            }
        }
    }
    
    private func draw(inImageView imageView: UIImageView, withTouch current: TouchRecord, previousTouch previous: TouchRecord?, andColor color: CGColor) {
        
        let size = imageView.frame.height
        
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
        UIGraphicsBeginImageContext(imageView.frame.size);
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
        UIGraphicsBeginImageContext(imageView.frame.size)
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












