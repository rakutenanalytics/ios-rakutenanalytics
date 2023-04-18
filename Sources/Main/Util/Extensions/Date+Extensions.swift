import Foundation

extension Date {

    var timeInSeconds: UInt {
        let hoursInSeconds = ((Calendar.current.component(.hour, from: self) * 60) * 60)
        let minutesInSeconds = (Calendar.current.component(.minute, from: self) * 60)
        return UInt((hoursInSeconds + minutesInSeconds))
    }

    static func timeIntervalBetween(current: Date, previous: Date) -> UInt {
        return UInt(current.timeIntervalSinceReferenceDate - previous.timeIntervalSinceReferenceDate)
    }
}
