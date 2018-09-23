//
//  UIViewExtensions.swift
//  UsefulBitsOfSwift
//
//  Created by Peter de Tagyos on 9/23/18.
//  Copyright © 2018 Peter de Tagyos. All rights reserved.
//

import UIKit


// MARK: - UIView

extension UIView {
    
    func changeAlpha(_ newAlpha: Float, secs: TimeInterval) {
        self.changeAlpha(newAlpha, secs: secs, completion: nil)
    }
    
    func changeAlpha(_ newAlpha: Float, secs: TimeInterval, completion: ((_ finished: Bool) -> Void)?) {
        UIView.animate(withDuration: secs, delay: 0.0, options: UIView.AnimationOptions.curveLinear, animations: { () -> Void in
            self.alpha = CGFloat(newAlpha)
        }, completion: completion)
    }
    
    // Find the UIView that is the first responder. Search recursively through all subviews as well.
    func firstResponder() -> UIView? {
        if self.isFirstResponder {
            return self
        }
        
        for subView in self.subviews {
            let fr = subView.firstResponder()
            if fr != nil {
                return fr
            }
        }
        
        return nil
    }
    
    // "Pop" the given view into visibility, before returning it to its original size
    func pop(_ durationInSeconds: TimeInterval, delayInSeconds: TimeInterval, onCompletion: ((_ finished: Bool) -> Void)?) {
        let originalFrame = self.frame
        let endWidth = self.frame.size.width * 1.2
        let endHeight = self.frame.size.height * 1.2
        let maxFrame = CGRect(x: self.frame.origin.x - ((endWidth - self.frame.size.width) / 2), y: self.frame.origin.y - ((endHeight - self.frame.size.height) /  2), width: endWidth, height: endHeight)
        
        self.alpha = 0.0
        
        UIView.animate(withDuration: durationInSeconds * 0.6, delay: delayInSeconds, options: UIView.AnimationOptions.curveLinear, animations: { () -> Void in
            self.alpha = 1.0
            self.frame = maxFrame
            
        }, completion: { (done) -> Void in
            UIView.animate(withDuration: durationInSeconds * 0.4, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: { () -> Void in
                self.frame = originalFrame
                
            }, completion: { (done) -> Void in
                onCompletion?(true)
            })
        })
        
    }
    
    func removeAllSubviews() {
        for subview in subviews {
            subview.removeFromSuperview()
        }
    }

    // Animate rotation of the view
    func rotate(degrees: Int, secs: TimeInterval) {
        UIView.animate(withDuration: secs) {
            self.transform = CGAffineTransform(rotationAngle: CGFloat(radiansForDegrees(degrees)))
        }
    }

    // Spin the view for the given number of revolutions
    func spin(_ secsForFullRotation: TimeInterval, repeatCount: Float, animationKey: String = "spinClockwise") {
        if self.layer.animation(forKey: animationKey) == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = Float(Double.pi * 2.0)
            rotationAnimation.duration = secsForFullRotation
            rotationAnimation.repeatCount = repeatCount
            
            self.layer.add(rotationAnimation, forKey: animationKey)
        }
    }
}

