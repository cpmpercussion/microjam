//
//  UIButtonExtensions.swift
//  microjam
//
//  Created by Charles Martin on 10/11/18.
//  Copyright © 2018 Charles Martin. All rights reserved.
//

import UIKit

/// Constant for the maximum glow opacity for record pulse animations.
let maximumGlowOpacity: Float = 0.9

/// UIButton Animation Extensions
extension UIButton{
    
    func setupGlowShadow(withColour colour: UIColor) {
        self.layer.shadowOffset = .zero
        self.layer.shadowColor = colour.cgColor
        self.layer.shadowRadius = 20
        self.layer.shadowOpacity = maximumGlowOpacity
        //        recEnableButton.layer.shadowPath = UIBezierPath(rect: recEnableButton.bounds).cgPath
        let glowWidth = self.bounds.height
        let glowOffset = 0.5 * (self.bounds.width - glowWidth)
        self.layer.shadowPath = UIBezierPath(ovalIn: CGRect(x: glowOffset,
                                                            y:0,
                                                            width: glowWidth,
                                                            height: glowWidth)).cgPath
    }
    
    func pulseGlow(withColour glowColour: UIColor, andTint tintColour: UIColor) {
        setupGlowShadow(withColour: glowColour)
        // Tint Color Animation
        self.tintColor = ButtonColors.recordDisabled
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveLinear, .repeat, .autoreverse], animations: {self.tintColor = ButtonColors.record}, completion: nil)
        
        // Shadow animation
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = 0.05
        animation.toValue = maximumGlowOpacity
        animation.duration = 0.25
        animation.repeatCount = 100000
        animation.autoreverses = true
        self.layer.add(animation, forKey: animation.keyPath)
        self.layer.shadowOpacity = 0.05
    }
    
    func pulseGlow() {
        pulseGlow(withColour: ButtonColors.recordGlow, andTint: ButtonColors.record)
    }
    
    func deactivateGlowing(withDeactivatedColour deactivatedColour: UIColor) {
        self.layer.removeAllAnimations()
        self.imageView?.layer.removeAllAnimations()
        self.layer.shadowOpacity = 0.0
        self.tintColor =  deactivatedColour
    }
    
    func deactivateGlowing() {
        deactivateGlowing(withDeactivatedColour: ButtonColors.recordDisabled)
    }
    
    func solidGlow(withColour glowColour: UIColor, andTint tintColour: UIColor) {
        self.layer.removeAllAnimations()
        self.imageView?.layer.removeAllAnimations()
        setupGlowShadow(withColour: glowColour)
        self.layer.shadowOpacity = maximumGlowOpacity
        self.tintColor = tintColour
    }
    
    func solidGlow() {
        solidGlow(withColour: ButtonColors.recordGlow, andTint: ButtonColors.record)
    }
    
}

/// Shake animation for a UIButton
extension UIButton {
    /// Shakes the button a little bit.
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 1.0
        animation.values = [-10.0, 10.0, -5.0, 5.0, -2.5, 2.5, -1, 1, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
    
    func stopBopping() {
        layer.removeAnimation(forKey: "bop")
    }
    
    func startBopping() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.2
        animation.values = [-2.5,2.5,0]
        animation.repeatCount = 100
        layer.add(animation, forKey: "bop")
    }
    
    func startSwirling() {
        let animationX = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animationX.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animationX.duration = 0.2
        animationX.values = [0,-2.5,2.5,0]
        animationX.repeatCount = 100
        let animationY = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animationY.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animationY.duration = 0.2
        animationY.values = [-2.5,0,0,2.5]
        animationY.repeatCount = 100
        layer.add(animationX, forKey: "swirl_x")
        layer.add(animationY, forKey: "swirl_y")
    }
    
    func stopSwirling() {
        layer.removeAnimation(forKey: "swirl_x")
        layer.removeAnimation(forKey: "swirl_y")
    }
}
