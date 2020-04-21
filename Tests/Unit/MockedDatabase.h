@import Foundation;
#import <RAnalytics/RAnalyticsDefines.h>


NS_ASSUME_NONNULL_BEGIN

@interface CurrentPage: UIViewController
@end

@interface MockedDatabase : NSObject
@property (nonatomic) NSMutableOrderedSet *keys;
@property (nonatomic) NSMutableDictionary *rows;
@property (nonatomic) NSDictionary        *latestAddedJSON;

- (void)insertBlobs:(NSArray<NSData *> *)blobs
               into:(NSString *)table
              limit:(unsigned int)maximumNumberOfBlobs
               then:(dispatch_block_t)completion;

- (void)fetchBlobs:(unsigned int)maximumNumberOfBlobs
              from:(NSString *)table
              then:(void (^)(NSArray<NSData *> *__nullable blobs, NSArray<NSNumber *> *__nullable identifiers))completion;

- (void)deleteBlobsWithIdentifiers:(NSArray<NSNumber *> *)identifiers
                                in:(NSString *)table
                              then:(dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
