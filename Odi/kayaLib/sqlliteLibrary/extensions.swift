//
//  extensions.swift
//  dbSql_tutorial
//
//  Created by Nok Danışmanlık on 15.10.2019.
//  Copyright © 2019 namikkaya. All rights reserved.
//

import Foundation
import UIKit
import SQLite


extension String {

    func toDate(withFormat format: String = "yyyy-MM-dd HH:mm:ss")-> Date?{

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)

        return date

    }
}

extension Date {
    
    func dateToStringUTC() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let utcTimeZoneStr = formatter.string(from: self)
        return utcTimeZoneStr
    }
    
    func dateNameString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let utcTimeZoneStr = formatter.string(from: self)
        return utcTimeZoneStr
    }
    func dateNameVideoString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
        let utcTimeZoneStr = formatter.string(from: self)
        return utcTimeZoneStr
    }
    
    func daysBetween(date: Date) -> Int {
        return Date.daysBetween(start: self, end: date)
    }

    // iki zaman arasında ki fark
    static func daysBetween(start: Date, end: Date) -> Int {
        let calendar = Calendar.current
        let date1 = calendar.startOfDay(for: start)
        let date2 = calendar.startOfDay(for: end)
        let a = calendar.dateComponents([.day], from: date1, to: date2)
        return a.value(for: .day)!
    }
    
}

extension Connection {
    public var userVersion: Int32 {
        get { return Int32(try! scalar("PRAGMA user_version") as! Int64)}
        set { try! run("PRAGMA user_version = \(newValue)") }
    }
}
