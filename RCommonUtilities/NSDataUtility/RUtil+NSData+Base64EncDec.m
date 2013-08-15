/*
 
 Reference from Rakuten iPhone Ichiba application code base
 Version: 1.6
 
 //  Base64EncDec.m
 //
 //  Created by Takeshi Yamane on 06/07/03.
 //  Copyright 2006 Takeshi Yamane. All rights reserved.
 //
 
 Reference from: https://github.com/daichi1128/DCAtomPub/blob/master/Base64EncDec.m
 */

#import "RUtil+NSData+Base64EncDec.h"

//Conversion table at the time of encoding / decoding
static const char	s_cBase64Tbl[] = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
    'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
    'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3',
    '4', '5', '6', '7', '8', '9', '+', '/'
    // '='
};

// CR/LF
static NSString		*s_pstrCRLF = @"\r\n";

// '-'
static NSString		*s_pstrEqual = @"=";


@implementation NSData (RUtil_NSData_Base64EncDec)
/*
 * @functionName : dataWithBase64CString 
 * @parameter1 : (const char *)pcBase64 
 * @parameter2 : (long)lLength
 * @return : void 
 * @description : Base64decodes string, NSData Create an object 
 */
+ (NSData *)dataWithBase64CString:(const char *)pcBase64 length:(long)lLength
{
	long	lCnt;
	int		nState, nVal;
	unsigned char	cNewData;
	NSMutableData	*pdatResult = [NSMutableData data];
    
	// Decryption
	nState	= 0;
    
	for ( lCnt = 0; lCnt < lLength && pcBase64[lCnt] != '='; lCnt++ ) {
		// Base64 Characters converted to an index number
		nVal = [NSData indexOfBase64Char:pcBase64[lCnt]];
		if ( nVal < 0 || nVal > (64 - 1) ) {
			// Undefined character is skipped
			continue;
		}
        
		switch ( nState ) {
            case 0:
                // If the value of 6bit top
                cNewData = nVal << 2;
                break;
                
            case 1:
                // If the following additional 2bit 6bit there is already
                cNewData |= (nVal & 0x30) >> 4;
                [pdatResult appendBytes:&cNewData length:1];
                
                // 4bit setting the beginning of the next position
                cNewData = (nVal & 0x0F) << 4;
                break;
                
            case 2:
                // If the following additional 4bit 4bit is already
                cNewData |= (nVal >> 2) & 0x0F;
                [pdatResult appendBytes:&cNewData length:1];
                
                // 2bit setting the beginning of the next position
                cNewData = (nVal & 0x03) << 6;
                break;
                
            case 3:
                // If the following additional 6bit 2bit there is already
                cNewData |= nVal & 0x3F;
                [pdatResult appendBytes:&cNewData length:1];
                break;
		}
        
		// State update
		nState++;
		if ( nState > 3 ) {
			// 3byte Back to the original separated
			nState = 0;
		}
	}
    
	return pdatResult;
}

/*
 * @functionName : dataWithBase64CString 
 * @parameter1 : (NSString *)pstrBase64 
 * @return : (NSData *) returns binary for passed base64String
 * @description : base64 decodes string, NSData creates an object
 */
+ (NSData *)dataWithBase64String:(NSString *)pstrBase64
{
	const char *pcBase64 = [pstrBase64 cStringUsingEncoding:NSASCIIStringEncoding];
	if ( pcBase64 == nil ) {
		return nil;
	}
    
	return [NSData dataWithBase64CString:pcBase64 length:[pstrBase64 lengthOfBytesUsingEncoding:NSASCIIStringEncoding]];
}

/*
 * @functionName : stringEncodedWithBase64 
 * @return : (NSString *) returns encoded string with Base64
 * @description : To generate the encoded string with Base64
 */ 
- (NSString *)stringEncodedWithBase64
{
	int			nState, nIndex, nLineCharCnt;
	unsigned	unCnt;
	const unsigned char	*pcRawData = [self bytes];
	unsigned	unLength   = [self length];
	NSMutableString *pstrResult = [NSMutableString string];
	nState		 = 0;
	nLineCharCnt = 0;
	unCnt		 = 0;
	while ( unCnt < unLength ) {
		switch ( nState ) {
            case 0:
                // If the position of the beginning of the byte
                // → top handle 6bit
                nIndex = (pcRawData[unCnt] >> 2) & 0x3F;
                break;
                
            case 1:
                // If the beginning of the next byte of the 4bit 2bit and the rest of the bytes
                nIndex = (pcRawData[unCnt] & 0x03) << 4;
                unCnt++;
                if ( unCnt < unLength ) {
                    // Only if there is a next byte
                    nIndex |= (pcRawData[unCnt] >> 4) & 0x0F;
                }
                break;
                
            case 2:
                // If the beginning of the next byte 2bit 4bit and the rest of the bytes
                nIndex = (pcRawData[unCnt] & 0x0F) << 2;
                unCnt++;
                if ( unCnt < unLength ) {
                    // Only if there is a next byte
                    nIndex |= (pcRawData[unCnt] >> 6) & 0x03;
                }
                break;
                
            case 3:
                // If the rest of the bytes 6bit
                nIndex = pcRawData[unCnt] & 0x03F;
                unCnt++;
                break;
		}
        
		// Store the result set in the area the character encoding conversion
		char	cConvChar[2];
		cConvChar[0] = s_cBase64Tbl[nIndex];
		cConvChar[1] = '\0';
		[pstrResult appendString:[NSString stringWithCString:cConvChar encoding:NSASCIIStringEncoding]];
		nLineCharCnt++;
        //		if ( (nLineCharCnt % 76) == 0 ) {
        //			// 76Insert new line for each character code
        //			[pstrResult appendString:s_pstrCRLF];
        //			nLineCharCnt = 0;
        //		}
        
		//State update
		nState++;
		if ( nState > 3 ) {
			// 3byteBack to the original separated
			nState = 0;
		}
	}
    
	// PaddingCharacter decision
	int	nPadCnt = 0;
	int	iPaddingIndex;
	switch ( nState ) {
        case 1:
        case 2:
            // 1If you end at byte
            nPadCnt = 2;
            break;
        case 3:
            // 2If you end at byte
            nPadCnt = 1;
            break;
	}
	for ( iPaddingIndex = 0; iPaddingIndex < nPadCnt; iPaddingIndex++ ) {
		[pstrResult appendString:s_pstrEqual];
		nLineCharCnt++;
		if ( (nLineCharCnt % 76) == 0 && iPaddingIndex+1 < nPadCnt ) {
			// 76Insert new line for each character code
			[pstrResult appendString:s_pstrCRLF];
			nLineCharCnt = 0;
		}
	}
    
	return pstrResult;
}

/*
 * @functionName : indexOfBase64Char 
 * @parameter1 : (char)cBase64Char: unichar character passed as input to this function
 * @return : returns index of the unchar character in the base64String
 * @description : To get the indexof the unchar character in the base64String.
 */
+ (int)indexOfBase64Char:(char)cBase64Char
{
	// Base64Character table search
	int	iCharIndex;
	for ( iCharIndex = 0; iCharIndex < 64; iCharIndex++ ) {
		if ( cBase64Char == s_cBase64Tbl[iCharIndex] ) {
			//! Notify the appropriate index
			return iCharIndex;
		}
	}
    
	// Undefined character
	return -1;
}

@end
