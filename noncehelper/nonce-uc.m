#include <stdio.h>
#include <mach/mach_error.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>

#define AppleMobileApNonce_RetrieveNonce 0xCA
#define AppleMobileApNonce_ClearNonce 0xC9
#define AppleMobileApNonce_GenerateNonce 0xC8

io_connect_t openApNonceService(void)
{
    CFMutableDictionaryRef nonceServiceDict = IOServiceMatching("AppleMobileApNonce");
    if(nonceServiceDict)
	{
		io_connect_t connect = 0;
		io_service_t nonceService = IOServiceGetMatchingService(kIOMasterPortDefault, nonceServiceDict);
		NSLog(@"nonceService = %d\n", nonceService);
		kern_return_t kr = IOServiceOpen(nonceService, mach_task_self(), 0, &connect);
		if(kr != KERN_SUCCESS)
		{
			NSLog(@"Failed to open nonce service %d %s\n", kr, mach_error_string(kr));
			return 0;
		}

        return connect;
	}

    return 0;
}

uint64_t UCGetNonce()
{
    io_connect_t apNonceConnect = openApNonceService();
    if(!apNonceConnect) return 0;

    size_t output_buffer_size = sizeof(uint64_t);
	uint64_t output_buffer = 0;

    __unused kern_return_t kr = IOConnectCallMethod(apNonceConnect, AppleMobileApNonce_RetrieveNonce, NULL, 0, 0, 0, 0, 0, &output_buffer, &output_buffer_size);
    
    NSLog(@"IOConnectCallMethod() => %d", kr);

    IOServiceClose(apNonceConnect);

    NSLog(@"got nonce %llX", output_buffer);

    return output_buffer;
}
