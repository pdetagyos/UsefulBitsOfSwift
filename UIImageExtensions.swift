//
//  UIImageExtensions.swift
//  UsefulBitsOfSwift
//
//  Created by Peter de Tagyos on 9/23/18.
//  Copyright © 2018 Peter de Tagyos. All rights reserved.
//

import UIKit


// MARK: - UIImage

extension UIImage {
    
    // Rotate the image data so that it correctly reflects the image orientation
    func correctOrientation() -> UIImage {
        switch self.imageOrientation {
        case .left:
            return self.rotate(radians: (3 * .pi) / 2)!
        case .right:
            return self.rotate(radians: .pi / 2)!
        default:
            // do nothing - we're already good
            return self
        }
    }
    
    // Generate a monochrome image in a given color
    convenience init(named: String, withColor: UIColor) {
        if let img = UIImage(named: named) {
            let width = img.size.width / UIScreen.main.scale
            let height = img.size.height / UIScreen.main.scale
            
            // Begin a new image context, to draw our colored image onto
            // Note: 0.0 allows for proper retina scaling
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0.0)
            if let context = UIGraphicsGetCurrentContext() {
                withColor.setFill()
                
                // Translate/flip the graphics context (for transforming from CG* coords to UI* coords)
                context.translateBy(x: 0, y: height)
                context.scaleBy(x: 1.0, y: -1.0)
                
                // Set the blend mode to normal (works best with originals that are white), and the original image
                context.setBlendMode(CGBlendMode.normal)
                let rect = CGRect(x: 0, y: 0, width: width, height: height)
                context.draw(img.cgImage!, in: rect)
                
                // Set a mask that matches the shape of the image, then draw a colored rectangle in our desired color
                context.clip(to: rect, mask: img.cgImage!)
                context.addRect(rect)
                context.drawPath(using: CGPathDrawingMode.fill)
                
                // Generate a new UIImage from the graphics context we drew onto
                let coloredImg = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                self.init(cgImage: coloredImg!.cgImage!)
                
            } else {
                self.init()
            }
            
        } else {
            self.init()
        }
    }
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
}


// Very helpful function

func radiansForDegrees(_ degrees: Int) -> Double {
    return Double(degrees) * .pi / 180.0;
}

