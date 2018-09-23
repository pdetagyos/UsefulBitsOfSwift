//
//  UILabelExtensions.swift
//  UsefulBitsOfSwift
//
//  Created by Peter de Tagyos on 9/23/18.
//  Copyright © 2018 Peter de Tagyos. All rights reserved.
//

import UIKit


// MARK: - UILabel

extension UILabel {
    
    // Return the number of lines the current text will be based on the current label width
    func lineCount() -> Int {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 1000.0))
        label.font = self.font
        label.text = self.text
        label.numberOfLines = 0
        label.sizeToFit()
        
        let charSize = lroundf(Float(self.font.lineHeight));
        let lineCount = lroundf(Float(label.bounds.size.height)) / charSize
        
        return lineCount
    }
    
    func setLineSpacing(_ lineSpacing: CGFloat = 0.0) {
        guard let labelText = self.text else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        
        let attributedString: NSMutableAttributedString
        if let labelAttributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelAttributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }
        
        // Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
        
        self.attributedText = attributedString
    }

}
