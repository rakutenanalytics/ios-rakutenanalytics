
#import <XCTest/XCTest.h>
#import <RAnalytics/_NSString+Encryption.h>
#import <CommonCrypto/CommonDigest.h>

@interface NSStringEncryptionTests : XCTestCase

@end

@implementation NSStringEncryptionTests

#pragma mark - Tests

- (void)test_encryption_simpleAlphaSpace {
    
    NSString *testString = @"Hello World";
    NSString *encryptedTestString = [testString rat_encrypt];
    NSString *correctEncryptionString = @"a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e";
    NSLog(@"alpha space %@",correctEncryptionString);
    XCTAssertEqualObjects(encryptedTestString, correctEncryptionString);
}

- (void)test_encryption_specialCharacters {
    
    NSString *testString = @"%\n!@#$%^^&*()_+`?><][{}|\n,./;'+-";
    NSString *encryptedTestString = [testString rat_encrypt];
    NSString *correctEncryptionString = @"8acec974d460f10fef6f0bf3ca83072272fb42bff12e8038bb49609580090df8";
    XCTAssertEqualObjects(encryptedTestString, correctEncryptionString);
}

- (void)test_encryption_numbers {
    
    NSString *testString = @"1234567890";
    NSString *encryptedTestString = [testString rat_encrypt];
    NSString *correctEncryptionString = @"c775e7b757ede630cd0aa1113bd102661ab38829ca52a6422ab782862f268646";
    XCTAssertEqualObjects(encryptedTestString, correctEncryptionString);
}

- (void)test_encryption_emptyString {
    NSString *testString = @"";
    NSString *encryptedTestString = [testString rat_encrypt];
    NSString *correctEncryptionString = @"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    XCTAssertEqualObjects(encryptedTestString, correctEncryptionString);
}

- (void)test_encryption_nil {
    NSString *testString = nil;
    NSString *encryptedTestString = [testString rat_encrypt];
    XCTAssertNil(encryptedTestString);
}

- (void)test_encryption_reallyLong {

    NSString *testString = @"Hello World";
    for (int i = 0; i < 5; i++) {
        testString = [testString stringByAppendingString:testString];
    }
    NSString *encryptedTestString = [testString rat_encrypt];
    NSString *correctEncryptionString = @"894842ce15ce7c19419b3b59e86db242518896d9f735d2d74a97f0664bd25007";
    XCTAssertEqualObjects(encryptedTestString, correctEncryptionString);
}

@end
