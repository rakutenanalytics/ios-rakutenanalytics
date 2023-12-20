import CoreLocation.CLLocation

extension CLLocation {
    // Note 1: == operand does not work with optional
    // Note 2: distance is preferred than == operand in the Objective-C legacy code
    static func equalLocation(lhs: CLLocation?, rhs: CLLocation?) -> Bool {
        guard let lhsNotOptional = lhs,
              let rhsNotOptional = rhs else {
            return lhs == nil && rhs == nil
        }
        return lhsNotOptional.distance(from: rhsNotOptional) == 0
    }
}
