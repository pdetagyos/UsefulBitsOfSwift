//
//  Utils.swift
//  UsefulBitsOfSwift
//
//  Created by Peter de Tagyos on 9/23/18.
//  Copyright © 2018 Peter de Tagyos. All rights reserved.
//

import CoreGraphics
import UIKit
import UserNotifications


typealias U = Utils

class Utils {
    
    
    // MARK: - File system helpers
    
    public static func appDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    public static func deleteFile(filename: String) {
        let documentsUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileUrl = documentsUrl.appendingPathComponent(filename)
        
        try? FileManager.default.removeItem(at: fileUrl)
    }
    
    public static func fileCountForDirectory(_ directoryUrl: URL) -> Int {
        var fileCount = 0
        
        if let fileEnumerator = FileManager.default.enumerator(at: directoryUrl, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in fileEnumerator {
                // Don't count video thumbnail images
                if !fileURL.path.hasSuffix("png") {
                    fileCount += 1
                }
            }
        }
        
        return fileCount
    }
    
    public static func loadImage(filename: String) -> UIImage? {
        let documentsUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileUrl = documentsUrl.appendingPathComponent(filename)
        if let i = UIImage(contentsOfFile: fileUrl.path) {
            return i
        }
        return nil
    }
    
    public static func saveImage(image: UIImage, filename: String) {
        let imgData = UIImagePNGRepresentation(image)
        let documentsUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let imageUrl = documentsUrl.appendingPathComponent(filename)
        try! imgData?.write(to: imageUrl)
    }
    

    // MARK: - Image helpers
    
    public static func base64StringForImage(_ image: UIImage?) -> String? {
        if let img = image {
            return UIImagePNGRepresentation(img)?.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithCarriageReturn)
        } else {
            return nil
        }
    }

    public static func downsizeImage(_ image: UIImage, scalingFactor: Float) -> UIImage? {
        let cgImage = image.cgImage
        
        let width = Int(Float((cgImage?.width)!) * scalingFactor)
        let height = Int(Float((cgImage?.height)!) * scalingFactor)
        let bitsPerComponent = cgImage?.bitsPerComponent
        let bytesPerRow = cgImage?.bytesPerRow
        let colorSpace = cgImage?.colorSpace
        let bitmapInfo = cgImage?.bitmapInfo
        
        if let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent!, bytesPerRow: bytesPerRow!, space: colorSpace!, bitmapInfo: (bitmapInfo?.rawValue)!) {
            context.interpolationQuality = CGInterpolationQuality.high
            
            context.draw(cgImage!, in: CGRect(origin: CGPoint.zero, size: CGSize(width: CGFloat(width), height: CGFloat(height))))
            
            var scaledImage = context.makeImage().flatMap { UIImage(cgImage: $0) }
            
            // See if we need to rotate the image - all images taken by the camera are tagged with the orientation: Landscape Left.
            // Not sure why they do this, but it causes images that are actually taken in portrait mode to display incorrectly. So if
            // we do have a portrait image here, rotate it so that it actually displays as portrait.
            // Ref: http://stackoverflow.com/questions/10600613/ios-image-orientation-has-strange-behavior
            
            if Int(image.size.width) != cgImage?.width {
                scaledImage = scaledImage?.imageRotatedByDegrees(90.0, flip: false)
            }
            
            return scaledImage
        }
        
        return image
    }

    public static func imageFromBase64String(_ b64String: String?) -> UIImage? {
        if let s = b64String {
            if let data = Foundation.Data(base64Encoded: s, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) {
                return UIImage(data: data)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    public static func imageFromURL(_ imageUrl: String, completion: @escaping (_ image: UIImage?, _ error: NSError?) -> Void) {
        if let url = URL(string: imageUrl) {
            let request = URLRequest(url: url)
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                if error == nil {
                    if data != nil {
                        let img = UIImage(data: data!)
                        completion(img, nil)
                        
                    } else {
                        completion(nil, NSError(domain: "Image", code: 600, userInfo: ["localizedDescription": "No data returned for image."]))
                    }
                } else {
                    completion(nil, error as NSError?)
                }
            })
            
            task.resume()
        }
    }
    
    public static func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    
    // MARK: - Date helpers
    
    static var dtFormatter: DateFormatter? = nil
    public static func dateFromDateTimeString(_ str: String?) -> Date? {
        if dtFormatter == nil {
            dtFormatter = DateFormatter()
            dtFormatter!.formatterBehavior = DateFormatter.Behavior.behavior10_4
            dtFormatter!.dateFormat = "MM-dd-yyyy HH:mm:ss"
            dtFormatter!.locale = Locale(identifier: "en_US_POSIX")
        }
        
        if let s = str {
            if s.count > 0 {
                return dtFormatter!.date(from: s)
            } else {
                return nil
            }
            
        } else {
            return nil
        }
    }
    
    static var nsFormatter: DateFormatter? = nil
    public static func dateFromNonStandardString(_ str: String?) -> Date? {
        if nsFormatter == nil {
            nsFormatter = DateFormatter()
            nsFormatter!.formatterBehavior = DateFormatter.Behavior.behavior10_4
            nsFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss"
            nsFormatter!.locale = Locale(identifier: "en_US_POSIX")
        }
        
        if let s = str {
            if s.count > 0 {
                return nsFormatter!.date(from: s)
            } else {
                return nil
            }
            
        } else {
            return nil
        }
    }
    
    public static func dateFromNumber(_ secondsSince1970: Double?) -> Date? {
        if secondsSince1970 != nil {
            return Date(timeIntervalSince1970: secondsSince1970!)
        } else {
            return nil
        }
    }
    
    public static func dateFromRFC3339String(_ rfc3339String: String?) -> Date? {
        if let s = rfc3339String {
            if s.count > 0 {
                return U.rfc3339DateFormatter().date(from: s)
            } else {
                return nil
            }
            
        } else {
            return nil
        }
    }
    
    public static func numberFromDate(_ date: Date?) -> Double? {
        if date != nil {
            return date!.timeIntervalSince1970
        } else {
            return nil
        }
    }
    
    static var formatter: DateFormatter? = nil
    public static func rfc3339DateFormatter() -> DateFormatter {
        if formatter == nil {
            formatter = DateFormatter()
            formatter!.formatterBehavior = DateFormatter.Behavior.behavior10_4
            formatter!.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZZZ'"
            formatter!.locale = Locale(identifier: "en_US_POSIX")
        }
        
        return formatter!
    }
    
    public static func rfc3339StringFromDate(_ date: Date?) -> String {
        if let dt = date {
            return U.rfc3339DateFormatter().string(from: dt)
        } else {
            return ""
        }
    }
    
    
    // MARK: Miscellaneous UIKit helpers
    
    public static func applyCircleMaskToView(_ view: UIView) {
        // Create a path with the rectangle in it.
        let path = CGMutablePath()
        let radius : CGFloat = view.bounds.width / 2
        
        path.addArc(center: CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2), radius: radius, startAngle: 0.0, endAngle: CGFloat(2.0 * Double.pi), clockwise: false)
        path.addRect(CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        
        let maskLayer = CAShapeLayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.path = path;
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        
        let overlayView = UIView(frame: view.bounds)
        overlayView.alpha = 1
        overlayView.backgroundColor = view.backgroundColor
        view.addSubview(overlayView)
        
        // PCT: Fix for iOS10 bug that hides views that have rounded corners or clipsToBounds set to true. WTF, Apple?
        overlayView.layoutIfNeeded()
        
        overlayView.layer.mask = maskLayer
        overlayView.clipsToBounds = true
    }
    
    public static func applyGradientMask(toView view: UIView) {
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = view.bounds
        gradientMaskLayer.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
        gradientMaskLayer.locations = [0.0, 1.0]
        view.layer.mask = gradientMaskLayer
    }
    
    public static func heightNeededForLabelContainingText(_ text: String, labelWidth: CGFloat, font: UIFont) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: labelWidth, height: 1000.0))
        label.font = font
        label.text = text
        label.numberOfLines = 0
        label.sizeToFit()
        
        return label.bounds.height
    }
    
    public static func widthNeededForLabelContainingText(_ text: String, labelHeight: CGFloat, font: UIFont) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 1000.0, height: labelHeight))
        label.font = font
        label.text = text
        label.numberOfLines = 0
        label.sizeToFit()
        
        return label.bounds.width
    }
    
    public static func showAlert(title: String?, message: String, closeButtonTitle: String, presenter: UIViewController?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: closeButtonTitle, style: .default))
        if presenter != nil {
            presenter!.present(ac, animated: true)
        } else {
            if let navCtrl =  UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
                navCtrl.visibleViewController?.present(ac, animated: true)
            }
        }
    }
    
    public static func showErrorDialog(_ message: String = "We're having some trouble talking to our servers right now. Sorry about that. Please try again in a few minutes.", presenter: UIViewController?) {
        showAlert(title: "Uh oh!", message: message, closeButtonTitle: "OK", presenter: presenter)
    }
    
    static var timestampTimeFormatter: DateFormatter? = nil
    static var timestampDateFormatter: DateFormatter? = nil
    public static func timestampStringForDate(_ date: Date?) -> String {
        // Returns a user-friendly string describing a timestamp from the past
        if date != nil {
            if date!.sameDayAs(Date()) {
                // From today - just return the time
                if timestampTimeFormatter == nil {
                    timestampTimeFormatter = DateFormatter()
                    timestampTimeFormatter!.dateFormat = "h:mma"
                }
                return timestampTimeFormatter!.string(from: date!)
                
            } else {
                // Get the date components and figure out far in the past the date occurred
                let cal = Calendar(identifier: Calendar.Identifier.gregorian)
                let comps = (cal as NSCalendar).components([.day, .month, .year], from: date!, to: Date(), options: NSCalendar.Options.matchStrictly)
                if comps.day == 1 {
                    return "Yesterday"
                } else if comps.day! > 1 && comps.month! < 1 {
                    return "\(comps.day!) days ago"
                } else if comps.month == 1 {
                    return "Last month"
                } else {
                    if timestampDateFormatter == nil {
                        timestampDateFormatter = DateFormatter()
                        timestampDateFormatter!.dateFormat = "MM/dd/yyyy"
                    }
                    return timestampDateFormatter!.string(from: date!)
                }
            }
            
        } else {
            return ""
        }
    }
    

    // MARK: - Miscellaneous helpers

    public static func delay(_ delay:Double, closure:@escaping ()->()) {
        // Execute the given closure on the main thread after the given delay in seconds
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    public static func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machine = systemInfo.machine
        var identifier = ""
        let mirror = Mirror(reflecting: machine)
        
        for child in mirror.children {
            let value = child.value
            
            if let value = value as? Int8, value != 0 {
                identifier.append(String(UnicodeScalar(UInt8(value))))
            }
        }
        
        return identifier
    }
    
    public static func isValidEmailAddress(_ stringToValidate: String) -> Bool {
        let validPattern = "^[_A-Za-z0-9-+]+(\\.[_A-Za-z0-9-+]+)*@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*(\\.[A-Za-z‌​]{2,4})$"
        
        return NSPredicate(format: "SELF MATCHES %@", validPattern).evaluate(with: stringToValidate)
    }
    
    public static func randomInt(_ min: Int, max:Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
    
    public static func stringForOrderedNumber(_ num: Int) -> String {
        switch num % 10 {
        case 1:
            if num != 11 {
                return "\(num)st"
            } else {
                return "11th"
            }
        case 2:
            if num != 12 {
                return "\(num)nd"
            } else {
                return "12th"
            }
        case 3:
            if num != 13 {
                return "\(num)rd"
            } else {
                return "13th"
            }
        default:
            return "\(num)th"
        }
    }
    
}
