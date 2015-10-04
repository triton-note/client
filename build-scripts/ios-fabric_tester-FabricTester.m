#import "FabricTester.h"

@implementation FabricTester
+ (void) start {
    FabricTester *obj = [FabricTester new];
    [NSThread detachNewThreadSelector:@selector(doTest) toTarget:obj withObject:nil];
}

- (void) doTest {
    @autoreleasepool {
        [NSThread sleepForTimeInterval:5];
        [CrashlyticsKit crash];
    }
}
@end
