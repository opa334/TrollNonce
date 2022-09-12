#include <stdio.h>
#import "nonce-uc.h"

#import "dimentio/libdimentio.h"
#import "exploit/exploit.h"
#import "exploit/kernel_rw.h"

#import "KernelManager.h"

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
				if(exploit_get_krw_and_kernel_base(&kernel_base) != 0)
				{
					return 1;
				}

				KernelManager* km = [KernelManager sharedInstance];
				[km loadOffsets];
				[km loadSlidOffsetsWithKernelBase:kernel_base];
				
				km.kread_32_d = kread32;
				km.kread_64_d = kread64;
				km.kwrite_32 = kwrite32;
				km.kwrite_64 = kwrite64;
				
				km.kcleanup = exploitation_cleanup;

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
				return 1;
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
