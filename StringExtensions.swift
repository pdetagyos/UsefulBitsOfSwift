//
//  StringExtensions.swift
//  UsefulBitsOfSwift
//
//  Created by Peter de Tagyos on 9/23/18.
//  Copyright © 2018 Peter de Tagyos. All rights reserved.
//

import Foundation
import UIKit


// MARK: - String

extension String {
    
    func sha1() -> String {
        // Generate the SHA1 hash of the current string
        let data = self.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1((data as NSData).bytes, CC_LONG(data.count), &digest)
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined(separator: "")
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
}


// MARK: - NSAttributedString

extension NSAttributedString {
    
    convenience init(string: String, fontName: String, fontSize: CGFloat, alignment: NSTextAlignment, lineHeight: CGFloat, letterSpacing: CGFloat = 0.0) {
        var attrs = [NSAttributedString.Key: AnyObject]()
        attrs[NSAttributedString.Key.font] = UIFont(name: fontName, size: fontSize)
        attrs[NSAttributedString.Key.kern] = letterSpacing as AnyObject?
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = alignment
        paraStyle.minimumLineHeight = lineHeight
        paraStyle.maximumLineHeight = lineHeight
        attrs[NSAttributedString.Key.paragraphStyle] = paraStyle
        self.init(string: string, attributes: attrs)
    }
    
}


// MARK: - NSMutableAttributedString

extension NSMutableAttributedString {
    
    // Append a string with the given attributes
    func appendString(_ stringToAppend: String, fontName: String, size: CGFloat, color: UIColor) {
        guard let font = UIFont(name: fontName, size: size) else { return }
        let attributes: [NSAttributedString.Key: AnyObject] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color]
        
        let attributedString = NSAttributedString(string: stringToAppend, attributes: attributes)
        
        self.append(attributedString)
    }
    
}
