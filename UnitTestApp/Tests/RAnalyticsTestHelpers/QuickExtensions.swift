import Quick
import Nimble
import Foundation

public extension QuickSpec {
    
    static func performAsyncTest(timeForExecution: TimeInterval, timeout: TimeInterval, expectation: @escaping () -> Void) {
        let totalTimeoutMS = Int((timeout + timeForExecution) * TimeInterval(USEC_PER_SEC))
        waitUntil(timeout: .microseconds(totalTimeoutMS)) { done in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                expectation()
                done()
            }
        }
    }
    
}


