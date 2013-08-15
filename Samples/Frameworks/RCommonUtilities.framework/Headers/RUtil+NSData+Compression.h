
 
// Reference from following link: http://stackoverflow.com/questions/8425012/is-there-a-practical-way-to-compress-nsdata

#import <Foundation/Foundation.h>

@interface NSData (RUtil_NSData_Compression)

// gzip compression and decompression utilities

/*
 inflate decompresses as much data as possible, and stops when the input buffer becomes empty or the output buffer
 becomes full. 
 This function provides decompressed binary data.
 */
- (NSData *)gzipInflate;
/*
 Deflate is a lossless data compression algorithm that uses a combination of the LZ77 algorithm and Huffman coding
 This function provides compressed binary data.
 */
- (NSData *)gzipDeflate;

@end
