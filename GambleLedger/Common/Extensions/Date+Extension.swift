// Date+Extension.swift
import Foundation

extension Date {
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    func endOfDay() -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: self.startOfDay())!
    }
    
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    func endOfMonth() -> Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: self.startOfMonth())!
    }
    
    func formattedString(format: String = "yyyy/MM/dd") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
    
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let unitFlags: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfYear, .month, .year]
        let components = (calendar as NSCalendar).components(unitFlags, from: self, to: now, options: [])
        
        if let year = components.year, year >= 1 {
            return year == 1 ? "1年前" : "\(year)年前"
        }
        
        if let month = components.month, month >= 1 {
            return month == 1 ? "1ヶ月前" : "\(month)ヶ月前"
        }
        
        if let week = components.weekOfYear, week >= 1 {
            return week == 1 ? "1週間前" : "\(week)週間前"
        }
        
        if let day = components.day, day >= 1 {
            return day == 1 ? "昨日" : "\(day)日前"
        }
        
        if let hour = components.hour, hour >= 1 {
            return hour == 1 ? "1時間前" : "\(hour)時間前"
        }
        
        if let minute = components.minute, minute >= 1 {
            return minute == 1 ? "1分前" : "\(minute)分前"
        }
        
        if let second = components.second, second >= 3 {
            return "\(second)秒前"
        }
        
        return "たった今"
    }
}
