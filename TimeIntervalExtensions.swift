//
//  TimeIntervalExtensions.swift
//  UsefulBitsOfSwift
//
//  Created by Peter de Tagyos on 9/23/18.
//  Copyright © 2018 Peter de Tagyos. All rights reserved.
//

import Foundation


// MARK: - TimeInterval

extension TimeInterval {

    // Return time interval for the given number of minutes
    static func minutes(_ minuteCount: Double) -> TimeInterval {
        return 60 * minuteCount
    }
    
    // Return time interval for the given number of hours
    static func hours(_ hourCount: Double) -> TimeInterval {
        return 60 * 60 * hourCount
    }
    
    // Return time interval for the given number of days
    static func days(_ dayCount: Double) -> TimeInterval {
        return 60 * 60 * 24 * dayCount
    }
    
    // Return count of full days represented by TimeInterval.
    // Any leftover fractional days are ignored.
    func asDays() -> Int {
        return Int(floor(self / (60 * 60 * 24)))
    }

}
