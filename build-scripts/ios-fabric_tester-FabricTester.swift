import Foundation

class FabricTester: NSObject {
    class func start() {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC))),
            dispatch_get_main_queue(), {
                CLSLogv("Gondra at: %@", getVaList([NSDate()]))
                Crashlytics.sharedInstance().throwException()
        })
    }
}
