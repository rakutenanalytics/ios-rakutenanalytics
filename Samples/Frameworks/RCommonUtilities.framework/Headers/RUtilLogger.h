#import <Foundation/Foundation.h>

#if DEBUG
#define RULog(A, ...) NSLog(@"DEBUG: %s:%d:%@", __PRETTY_FUNCTION__,__LINE__,[NSString stringWithFormat:A, ## __VA_ARGS__]);
#else
#define RULog(A, ...)
#endif