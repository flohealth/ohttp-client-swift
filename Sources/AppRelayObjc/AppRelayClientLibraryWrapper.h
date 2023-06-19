#import <Foundation/Foundation.h>
#import "apprelay.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppRelayClientLibraryWrapper : NSObject

+ (void)initialieLogging;

+ (nullable NSString *)lastErrorMessage;

+ (nullable RequestContext *)encapsulateRequest:(NSData *)requestData config:(NSData *)config;

+ (NSData *)encapsulatedRequestFromContext:(RequestContext *)context;

+ (void)dropRequestContext:(RequestContext *)context;

+ (nullable NSData*)decapsulateResponseFromContext:(RequestContext*)context encapsulatedResponse:(NSData *)encapsulatedResponse;

@end

NS_ASSUME_NONNULL_END
