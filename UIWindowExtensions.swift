//
//  UIWindowExtensions.swift
//  UsefulBitsOfSwift
//
//  Created by Peter de Tagyos on 9/23/18.
//  Copyright © 2018 Peter de Tagyos. All rights reserved.
//

import UIKit


// MARK: - UIWindow -

extension UIWindow {
    public var visibleViewController: UIViewController? {
        get {
            return UIWindow.getVisibleViewController(from: self.rootViewController)
        }
    }
    
    public static func getVisibleViewController(from vc: UIViewController?) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return UIWindow.getVisibleViewController(from: nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return UIWindow.getVisibleViewController(from: tc.selectedViewController)
        } else {
            if let pvc = vc?.presentedViewController {
                return UIWindow.getVisibleViewController(from: pvc)
            } else {
                return vc
            }
        }
    }
}
