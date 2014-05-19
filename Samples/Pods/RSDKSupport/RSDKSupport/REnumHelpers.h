//
//  REnumHelpers.h
//  RSDKSupport
//
//  Created by Gatti, Alessandro | Alex | SDTD on 6/10/13.
//  Copyright (c) 2013 Rakuten Inc. All rights reserved.
//

/**
 * Backported definition for NS_ENUM.
 */
#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif // NS_ENUM

/**
 * Backported definition for NS_OPTIONS.
 */
#ifndef NS_OPTIONS
#define NS_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
#endif // NS_OPTIONS
