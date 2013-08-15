// Reference from following link: http://stackoverflow.com/questions/8425012/is-there-a-practical-way-to-compress-nsdata

#import "RUtil+NSData+Compression.h"
#import "zlib.h"

@implementation NSData (RUtil_NSData_Compression)
/*
 * @functionName : gzipInflate 
 * @return : returns the decompressed data from  binary data 
 * @description : Decompression of binary data is performed 
 */
- (NSData *)gzipInflate
{
	if ([self length] == 0) return self;
	
	unsigned fullDataLength = [self length];
	unsigned halfDatalength = [self length] / 2;
	
	NSMutableData *decompressedBinaryData = [NSMutableData dataWithLength: fullDataLength + halfDatalength];
	BOOL done = NO;
	int status;
	
	z_stream streamForInflate;
	streamForInflate.next_in = (Bytef *)[self bytes];
	streamForInflate.avail_in = [self length];
	streamForInflate.total_out = 0;
	streamForInflate.zalloc = Z_NULL;
	streamForInflate.zfree = Z_NULL;
	
	int windowBitsValue = 15+32;
	
	if (inflateInit2(&streamForInflate, windowBitsValue) != Z_OK) return nil;
	while (!done)
	{
		// Make sure we have enough room and reset the lengths.
		if (streamForInflate.total_out >= [decompressedBinaryData length])
			[decompressedBinaryData increaseLengthBy: halfDatalength];
		streamForInflate.next_out = [decompressedBinaryData mutableBytes] + streamForInflate.total_out;
		streamForInflate.avail_out = [decompressedBinaryData length] - streamForInflate.total_out;
		
		// Inflate another chunk.
		status = inflate (&streamForInflate, Z_SYNC_FLUSH);
		if (status == Z_STREAM_END) done = YES;
		else if (status != Z_OK) break;
	}
	if (inflateEnd (&streamForInflate) != Z_OK) return nil;
	
	// Set real length.
	if (done)
	{
		[decompressedBinaryData setLength: streamForInflate.total_out];
		return [NSData dataWithData: decompressedBinaryData];
	}
	else return nil;
}

/*
 * @functionName : gzipDeflate 
 * @return : returns the compressed binary data 
 * @description : Compression of binary data is performed 
 */
- (NSData *)gzipDeflate
{
	if ([self length] == 0) return self;
	
	z_stream streamForDeflate;
	
	streamForDeflate.zalloc = Z_NULL;
	streamForDeflate.zfree = Z_NULL;
	streamForDeflate.opaque = Z_NULL;
	streamForDeflate.total_out = 0;
	streamForDeflate.next_in=(Bytef *)[self bytes];
	streamForDeflate.avail_in = [self length];
	
	int windowBitsValue = 15+16;
	
	if (deflateInit2(&streamForDeflate, Z_BEST_COMPRESSION, Z_DEFLATED, windowBitsValue, 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
	
	NSMutableData *compressedBinaryData = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
	
	do {
		
		if (streamForDeflate.total_out >= [compressedBinaryData length])
			[compressedBinaryData increaseLengthBy: 16384];
		
		streamForDeflate.next_out = [compressedBinaryData mutableBytes] + streamForDeflate.total_out;
		streamForDeflate.avail_out = [compressedBinaryData length] - streamForDeflate.total_out;
		
		deflate(&streamForDeflate, Z_FINISH);  
		
	} while (streamForDeflate.avail_out == 0);
	
	deflateEnd(&streamForDeflate);
	
	[compressedBinaryData setLength: streamForDeflate.total_out];
	return [NSData dataWithData:compressedBinaryData];
}

@end
