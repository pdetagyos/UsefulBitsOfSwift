//
//  DateExtensions.swift
//  UsefulBitsOfSwift
//
//  Created by Peter de Tagyos on 9/23/18.
//  Copyright © 2018 Peter de Tagyos. All rights reserved.
//

import Foundation


// MARK: - NSDate

extension Date {
    
    func beginningOfDay() -> Date {
        // Normalize to midnight, extract the year, month, and day components and create a new date from those components.
        let calendar = Calendar.current
        let unitFlags: NSCalendar.Unit = [.day, .month, .year]
        let comps = (calendar as NSCalendar).components(unitFlags, from: self)
        
        return calendar.date(from: comps)!
    }
    
    func beginningOfWeek() -> Date {
        let calendar = Calendar.current
        var beginning: NSDate? = nil
        let found = (calendar as NSCalendar).range(of: .weekOfMonth, start: &beginning, interval: nil, for: self)
        if found && beginning != nil {
            return beginning! as Date
        }
        
        // Couldn't calc via range, so try to backtrack from today to Sunday
        let weekdayComps = (calendar as NSCalendar).components(NSCalendar.Unit.weekday, from: self)
        
        // Create a date components to represent the number of days to subtract from the current date.
        // The weekday value for Sunday in the Gregorian calendar is 1, so subtract 1 from the number of days to subtract from the date in question.  (If today's Sunday, subtract 0 days.)
        var compsToSubtract = DateComponents()
        compsToSubtract.day = 0 - (weekdayComps.weekday! - 1)
        beginning = (calendar as NSCalendar).date(byAdding: compsToSubtract, to: self, options: NSCalendar.Options.matchStrictly) as NSDate?
        
        // Normalize to midnight, extract the year, month, and day components and create a new date from those components.
        let unitFlags: NSCalendar.Unit = [.day, .month, .year]
        if beginning != nil {
            let comps = (calendar as NSCalendar).components(unitFlags, from: beginning! as Date)
            
            return calendar.date(from: comps)!
        }
        
        return self
    }
    
    func dateByAddingYears(_ years: Int, months: Int, days: Int, hours: Int, minutes: Int, seconds: Int) -> Date {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let unitFlags: NSCalendar.Unit = [.day, .month, .year, .hour, .minute, .second]
        var comps = (calendar as NSCalendar).components(unitFlags, from: self)
        comps.year = comps.year! + years
        comps.month = comps.month! + months
        comps.day = comps.day! + days
        comps.hour = comps.hour! + hours
        comps.minute = comps.minute! + minutes
        comps.second = comps.second! + seconds
        
        return calendar.date(from: comps)!
    }
    
    func dayOfMonth() -> Int {
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components(NSCalendar.Unit.day, from: self)
        return components.day!
    }
    
    func dayOfWeek() -> Int {
        // Note: The first day of the week (Sunday) has ordinal = 1, not 0
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components(NSCalendar.Unit.weekday, from: self)
        return components.weekday!
    }
    
    func daysFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.day, from: date, to: self, options: []).day!
    }
    
    static func defaultCalendar() -> Calendar {
        var defCal = Calendar(identifier: Calendar.Identifier.gregorian)
        defCal.timeZone = TimeZone.autoupdatingCurrent
        return defCal
    }
    
    func endOfDay() -> Date {
        // Normalize to midnight, extract the year, month, and day components and create a new date from those components.
        let calendar = Calendar.current
        let unitFlags: NSCalendar.Unit = [.day, .month, .year]
        var comps = (calendar as NSCalendar).components(unitFlags, from: self)
        comps.hour = 23
        comps.minute = 59
        comps.second = 59
        
        return calendar.date(from: comps)!
    }
    
    func endOfWeek() -> Date {
        // Since we want the week end date to also be set to 23:59:59, we'll figure out the beginning of the week
        // (at 00:00:00), then add a week minus 1 second
        let calendar = Calendar.current
        let startOfWeek = self.beginningOfWeek()
        var compsToAdd = DateComponents()
        compsToAdd.day = 6
        compsToAdd.hour = 23
        compsToAdd.minute = 59
        compsToAdd.second = 59
        
        return (calendar as NSCalendar).date(byAdding: compsToAdd, to: startOfWeek, options: NSCalendar.Options.matchStrictly)!
    }
    
    func isInPast() -> Bool {
        return self.timeIntervalSinceNow < 0.0
    }
    
    func minutesFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.minute, from: date, to: self, options: []).minute!
    }
    
    func sameDayAs(_ other: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: other)
    }
    
    func weekday() -> Int {
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components(.weekday, from: self)
        return components.weekday!
    }
    
    func yearsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.year, from: date, to: self, options: []).year!
    }
    
}
