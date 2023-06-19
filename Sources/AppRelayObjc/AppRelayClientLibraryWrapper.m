#import "AppRelayClientLibraryWrapper.h"
#import "apprelay.h"

@implementation AppRelayClientLibraryWrapper

+ (void)initialieLogging {
    initialize_logging();
}

+ (NSString *)lastErrorMessage {
    int errorLength = last_error_length();
    
    if (errorLength <= 0) {
        return nil;
    }
    
    char errorBuffer[errorLength + 1]; // +1 for null terminator at the end of a string
    int bytesWritten = last_error_message(errorBuffer, errorLength + 1);
    
    if (bytesWritten <= 0) {
        return @"Unknown error";
    }
    
    return [NSString stringWithCString:errorBuffer encoding:NSUTF8StringEncoding];
}

+ (RequestContext*)encapsulateRequest:(NSData *)requestData config:(NSData *)config {
    RequestContext* context = encapsulate_request_ffi(
        (const uint8_t *)[config bytes],
        (size_t)[config length],
        (const uint8_t *)[requestData bytes],
        (size_t)[requestData length]
    );
    
    if (context == NULL || last_error_length() > 0) {
        return nil;
    } else {
        return context;
    }
}

+ (NSData *)encapsulatedRequestFromContext:(RequestContext *)context {
    return [[NSData alloc] initWithBytes:(const uint8_t *)request_context_message_ffi(context)
                                  length:(size_t)request_context_message_len_ffi(context)];
}

+ (void)dropRequestContext:(RequestContext *)context {
    request_context_message_drop_ffi(context);
}

+ (NSData *)decapsulateResponseFromContext:(RequestContext *)context encapsulatedResponse:(NSData *)encapsulatedResponse {
    ResponseContext* responseContext = decapsulate_response_ffi(context, [encapsulatedResponse bytes], [encapsulatedResponse length]);
    
    if (responseContext == NULL || last_error_length() > 0) {
        return nil;
    }
    
    return [[NSData alloc] initWithBytes:(const uint8_t *)response_context_message_ffi(responseContext)
                                  length:(size_t)response_context_message_len_ffi(responseContext)];
}

@end
