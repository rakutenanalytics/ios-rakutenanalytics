//
//  NSHTTPURLResponse+RAExtensions.h
//  Authentication
//
//  Created by Gatti, Alessandro | Alex | SDTD on 5/9/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

@import Foundation;

/**
 * Category extending `NSHTTPURLResponse` with additions needed by the
 * Rakuten SDK.
 *
 * @category NSHTTPURLResponse(RAExtensions) NSHTTPURLResponse+RAExtensions.h <RSDKSupport/NSHTTPURLResponse+RAExtensions.h>
 */
@interface NSHTTPURLResponse (RAExtensions)

/**
 * Returns the text encoding of the response.
 *
 * @return The text encoding returned in the request, or
 *         `NSUTF8StringEncoding` if none has been sent by the HTTP
 *         server.
 */
- (NSStringEncoding)textEncoding;

@end
