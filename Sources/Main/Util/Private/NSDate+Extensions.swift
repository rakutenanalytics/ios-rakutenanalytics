import Foundation

extension NSDate {
    var toString: String {
        // Using the following code would result in libICU being lazily loaded along with
        // its 16MB of data, and the latter would never get deallocated. No thanks, iOS!
        //
        // ```
        // NSDateFormatter *startTimeFormatter = NSDateFormatter.new;
        // startTimeFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        // startTimeFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        // startTimeFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        // NSString *startTime = [startTimeFormatter stringFromDate:NSDate.date];
        // ```
        //
        // Think NSCalendar is the solution? No luck, it loads ICU too! Instead,
        // we just use a few lines of C, which allocate about 20KB. It's OK as we don't need
        // any fancy locale.

        // The reason I don't use gettimeofday (2) is that it's a BSD 4.2 function, it's not part
        // of the standard C library, and I'm not sure how Apple feels about using those.
        //
        // -[NSDate timeIntervalSince1970] gives the same result anyway.
        let timeInterval = timeIntervalSince1970

        var tod = timeval()
        tod.tv_sec  = __darwin_time_t(ceil(timeInterval))
        tod.tv_usec = __darwin_suseconds_t(ceil((timeInterval - Double(tod.tv_sec)) * Double(NSEC_PER_MSEC)))

        // localtime (3) reuses an internal buffer, so the pointer it returns must never get
        // free (3)'d. localtime (3) is ISO C90 so it's safe to use without having to worry
        // about Apple's wrath.

        let time = localtime(&tod.tv_sec).pointee

        // struct tm's epoc is 1900/1/1. Months start at 0.

        return String(format: "%04u-%02u-%02u %02u:%02u:%02u", 1900 + time.tm_year,
                      1 + time.tm_mon,
                      time.tm_mday,
                      time.tm_hour,
                      time.tm_min,
                      time.tm_sec)
    }

    static func daysPassedSinceDate(_ date: Date?) -> Int64 {
        guard let date = date else {
            return Int64(0)
        }
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
        let result = calendar?.components(.day, from: date as Date, to: Date(), options: NSCalendar.Options(rawValue: 0)).day
        return Int64(result ?? 0)
    }
}
