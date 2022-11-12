#include <stdio.h>
#import "nonce-uc.h"

#import "dimentio/libdimentio.h"
#import "exploit/multicast_bytecopy/exploit.h"
#import "exploit/multicast_bytecopy/kernel_rw.h"
@import CoreML;
#import <mach-o/loader.h>
#import "exploit/weightBufs/AppleNeuralEngine/_ANEDeviceInfo.h"

int wb_exploit(uint64_t* kernel_base);
void wb_cleanup(void);
uint32_t kread32_wb(uint64_t address);
uint64_t kread64_wb(uint64_t address);
void kwrite64_wb(uint64_t address,uint64_t value);

CFTypeRef MGCopyAnswer(CFStringRef);

cpu_subtype_t subtypeToUse = 0;

#import "KernelManager.h"

extern char*** _NSGetArgv();
NSString* safe_getExecutablePath()
{
	char* executablePathC = **_NSGetArgv();
	return [NSString stringWithUTF8String:executablePathC];
}

#ifndef kCFCoreFoundationVersionNumber_iOS_15_1
#define kCFCoreFoundationVersionNumber_iOS_15_1 1855.105
#endif

@import Foundation;

kern_return_t dim_read(kaddr_t a, void* d, size_t s)
{
    KernelManager* km = [KernelManager sharedInstance];
    return [km readBufferAtAddress:a intoBuffer:d withLength:s];
}

kern_return_t dim_write(kaddr_t a, const void* d, size_t s)
{
    KernelManager* km = [KernelManager sharedInstance];
    return [km writeBuffer:(void*)d withLength:s toAddress:a];
}


int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
		NSLog(@"ok");
		if(argc < 2) return -1;

		NSLog(@"noncehelper %d", getuid());

		NSString* selector = [NSString stringWithUTF8String:argv[1]];

		if([selector isEqualToString:@"set-nonce"])
		{
			BOOL suc = NO;
			if(argc < 3) return -1;
			NSString* nonceString = [NSString stringWithUTF8String:argv[2]];

			NSScanner* scanner = [NSScanner scannerWithString:nonceString];
			uint64_t nonce = 0;
			[scanner scanHexLongLong:&nonce];
			uint64_t nonceToSet = nonce;

			if(nonce)
			{
				uint64_t kernel_base = 0;
				KernelManager* km = [KernelManager sharedInstance];

				CFTypeRef hasAppleNeuralEngine = MGCopyAnswer(CFSTR("HasAppleNeuralEngine"));
				if(kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_15_1) // supports A10-A15
				{
					NSLog(@"exploiting using multicast_bytecopy");
					if(mb_exploit_get_krw_and_kernel_base(&kernel_base) != 0)
					{
						return 1;
					}
					[km loadOffsets];
					[km loadSlidOffsetsWithKernelBase:kernel_base];
					km.kread_32_d = kread32_mb;
					km.kread_64_d = kread64_mb;
					km.kwrite_32 = kwrite32_mb;
					km.kwrite_64 = kwrite64_mb;
					km.kcleanup = exploitation_cleanup;
				}
				else if(hasAppleNeuralEngine == kCFBooleanTrue) // supports A12-A14
				{
					NSLog(@"exploiting using weightBufs");

					// Find some precompiled model and get the cpusubtype of it because we need it in the exploit
					NSURL* anedCrap = [NSURL fileURLWithPath:@"/System/Library/ImagingNetworks"];
					NSDirectoryEnumerator<NSURL*>* enumerator = [[NSFileManager defaultManager] enumeratorAtURL:anedCrap 
                         includingPropertiesForKeys:nil 
                                            options:0 
                                       errorHandler:nil];
					NSURL* file;
					NSString* aneSubType = [_ANEDeviceInfo aneSubType].uppercaseString;
					while(file = [enumerator nextObject])
					{
						if([file.pathExtension isEqualToString:@"hwx"] && [file.lastPathComponent containsString:aneSubType])
						{
							struct mach_header header;
							FILE* f = fopen(file.fileSystemRepresentation, "r");
							if(!f) continue;
							fread(&header, sizeof(struct mach_header), 1, f);
							fclose(f);
							subtypeToUse = header.cpusubtype;
							break;
						}
					}

					while(1)
					{
						wb_exploit(&kernel_base);
						if(kernel_base)
						{
							if(kread64_wb(kernel_base) == 0x100000CFEEDFACF)
							{
								// exploit worked, continue
								break;
							}
						}
						// otherwise, try again
					}
					[km loadOffsets];
					[km loadSlidOffsetsWithKernelBase:kernel_base];
					km.kread_32_d = kread32_wb;
					km.kread_64_d = kread64_wb;
					km.kwrite_64 = kwrite64_wb;
					km.kcleanup = wb_cleanup;
				}
				else
				{
					return 5;
				}

				NSLog(@"krw active now!");
				NSLog(@"about to set nonce 0x%llX", nonce);

				size_t nonce_d_sz;
				uint8_t nonce_d[CC_SHA384_DIGEST_LENGTH];
				
				kern_return_t preInitRet = dimentio_preinit(&nonce, true, &nonce_d[0], &nonce_d_sz);
				if(preInitRet != KERN_SUCCESS)
				{
					dimentio_init(km.kernel_base, dim_read, dim_write);
					kern_return_t mainRet = dimentio(&nonce, true, &nonce_d[0], &nonce_d_sz);
					suc = (mainRet == 0) && nonceToSet == nonce;
				}
				
				dimentio_term();

				[km finishAndCleanupIfNeeded];

				if(suc == YES) return 0;
			}
		}
		else if([selector isEqualToString:@"get-nonce"])
		{
			uint64_t nonce = UCGetNonce();
			if(nonce)
			{
				printf("0x%llX\n", nonce);
			}
			else
			{
				printf("Error\n");
			}
		}

		return 0;
	}
}
