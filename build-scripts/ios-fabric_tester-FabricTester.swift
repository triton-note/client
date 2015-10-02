import Foundation

@objc(FabricTester)
class FabricTester: NSObject {
    class func start() {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC))),
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                CLSLogv("Gondra at: %@", getVaList([NSDate()]))
                Crashlytics.sharedInstance().throwException()
        })
    }
}
