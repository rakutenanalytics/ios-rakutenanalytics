#import "_RLogger.h"

@implementation _RLogger

static RLoggingLevel _loggingLevel = RLoggingLevelError;

+ (RLoggingLevel)loggingLevel {
    return _loggingLevel;
}

+ (void)setLoggingLevel:(RLoggingLevel)value {
    _loggingLevel = value;
}

+ (NSString * _Nullable )verbose:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    NSString *message = [_RLogger log:RLoggingLevelVerbose format:format argList:argList];
    va_end(argList);
    return message;
}

+ (NSString * _Nullable )debug:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    NSString *message = [_RLogger log:RLoggingLevelDebug format:format argList:argList];
    va_end(argList);
    return message;
}

+ (NSString * _Nullable )info:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    NSString *message = [_RLogger log:RLoggingLevelInfo format:format argList:argList];
    va_end(argList);
    return message;
}

+ (NSString * _Nullable )warning:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    NSString *message = [_RLogger log:RLoggingLevelWarning format:format argList:argList];
    va_end(argList);
    return message;
}

+ (NSString * _Nullable )error:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    NSString *message = [_RLogger log:RLoggingLevelError format:format argList:argList];
    va_end(argList);
    return message;
}

+ (NSString * _Nullable)log:(RLoggingLevel)loggingLevel format:(NSString *)format argList:(va_list)argList
{
    if ([_RLogger loggingLevel] > loggingLevel ||
        [_RLogger loggingLevel] == RLoggingLevelNone ||
        !format)
    {
        return nil;
    }

    NSString *message = [[NSString alloc] initWithFormat:format arguments: argList];
    
    switch (loggingLevel) {
        case RLoggingLevelVerbose:
#ifdef DEBUG
            NSLog(@"🟢 RAnalytics(Verbose): %@", message);
#endif
            break;
        case RLoggingLevelDebug:
#ifdef DEBUG
            NSLog(@"🟡 RAnalytics(Debug): %@", message);
#endif
            break;
        case RLoggingLevelInfo:
            NSLog(@"🔵 RAnalytics(Info): %@", message);
            break;
        case RLoggingLevelWarning:
            NSLog(@"🟠 RAnalytics(Warning): %@", message);
            break;
        case RLoggingLevelError:
            NSLog(@"🔴 RAnalytics(Error): %@", message);
            break;
        default:
            break;
    }
    return message;
}

@end
