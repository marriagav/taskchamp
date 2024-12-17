import Foundation

extension Calendar {
    func mergeDateWithTime(date: Date?, time: Date?) -> Date? {
        if let date {
            var components = dateComponents([.year, .month, .day], from: date)
            if let time {
                let timeComponents = dateComponents([.hour, .minute], from: time)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
            }
            return self.date(from: components)
        }
        return nil
    }
}
