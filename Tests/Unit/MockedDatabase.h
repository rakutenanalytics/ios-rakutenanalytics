@import Foundation;
#import <RAnalytics/RAnalyticsDefines.h>

NS_ASSUME_NONNULL_BEGIN

@interface CurrentPage: UIViewController
@end

@interface MockedDatabase : NSObject
@property (nonatomic) NSMutableOrderedSet *keys;
@property (nonatomic) NSMutableDictionary *rows;
@property (nonatomic) NSDictionary        *latestAddedJSON;

- (void)insertBlob:(NSData *)blob
              into:(NSString *)table
             limit:(NSUInteger)maximumNumberOfBlobs
              then:(dispatch_block_t)completion;

- (void)insertBlobs:(NSArray<NSData *> *)blobs
               into:(NSString *)table
              limit:(NSUInteger)maximumNumberOfBlobs
               then:(dispatch_block_t)completion;

- (void)fetchBlobs:(NSUInteger)maximumNumberOfBlobs
              from:(NSString *)table
              then:(void (^)(NSArray<NSData *> * _Nullable, NSArray<NSNumber *> * _Nullable))completion;

- (void)deleteBlobsWithIdentifiers:(NSArray<NSNumber *> *)identifiers
                                in:(NSString *)table
                              then:(dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
