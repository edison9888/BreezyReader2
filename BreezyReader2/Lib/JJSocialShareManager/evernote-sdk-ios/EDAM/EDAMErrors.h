/**
 * Autogenerated by Thrift
 *
 * DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
 */

#import <Foundation/Foundation.h>

#import "TProtocol.h"
#import "TApplicationException.h"
#import "TProtocolUtil.h"
#import "TProcessor.h"


enum EDAMErrorCode {
  EDAMErrorCode_UNKNOWN = 1,
  EDAMErrorCode_BAD_DATA_FORMAT = 2,
  EDAMErrorCode_PERMISSION_DENIED = 3,
  EDAMErrorCode_INTERNAL_ERROR = 4,
  EDAMErrorCode_DATA_REQUIRED = 5,
  EDAMErrorCode_LIMIT_REACHED = 6,
  EDAMErrorCode_QUOTA_REACHED = 7,
  EDAMErrorCode_INVALID_AUTH = 8,
  EDAMErrorCode_AUTH_EXPIRED = 9,
  EDAMErrorCode_DATA_CONFLICT = 10,
  EDAMErrorCode_ENML_VALIDATION = 11,
  EDAMErrorCode_SHARD_UNAVAILABLE = 12,
  EDAMErrorCode_LEN_TOO_SHORT = 13,
  EDAMErrorCode_LEN_TOO_LONG = 14,
  EDAMErrorCode_TOO_FEW = 15,
  EDAMErrorCode_TOO_MANY = 16,
  EDAMErrorCode_UNSUPPORTED_OPERATION = 17
};

@interface EDAMUserException : NSException <NSCoding> {
  int __errorCode;
  NSString * __parameter;

  BOOL __errorCode_isset;
  BOOL __parameter_isset;
}

- (id) initWithErrorCode: (int) errorCode parameter: (NSString *) parameter;

- (void) read: (id <TProtocol>) inProtocol;
- (void) write: (id <TProtocol>) outProtocol;

#if TARGET_OS_IPHONE || (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
@property (nonatomic, getter=errorCode, setter=setErrorCode:, assign) int errorCode;
@property (nonatomic, getter=parameter, setter=setParameter:, strong) NSString * parameter;
#else

- (int) errorCode;
- (void) setErrorCode: (int) errorCode;

- (NSString *) parameter;
- (void) setParameter: (NSString *) parameter;

#endif

- (BOOL) errorCodeIsSet;
- (BOOL) parameterIsSet;
@end

@interface EDAMSystemException : NSException <NSCoding> {
  int __errorCode;
  NSString * __message;

  BOOL __errorCode_isset;
  BOOL __message_isset;
}

- (id) initWithErrorCode: (int) errorCode message: (NSString *) message;

- (void) read: (id <TProtocol>) inProtocol;
- (void) write: (id <TProtocol>) outProtocol;

#if TARGET_OS_IPHONE || (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
@property (nonatomic, getter=errorCode, setter=setErrorCode:, assign) int errorCode;
@property (nonatomic, getter=message, setter=setMessage:, strong) NSString * message;
#else

- (int) errorCode;
- (void) setErrorCode: (int) errorCode;

- (NSString *) message;
- (void) setMessage: (NSString *) message;

#endif

- (BOOL) errorCodeIsSet;
- (BOOL) messageIsSet;
@end

@interface EDAMNotFoundException : NSException <NSCoding> {
  NSString * __identifier;
  NSString * __key;

  BOOL __identifier_isset;
  BOOL __key_isset;
}

- (id) initWithIdentifier: (NSString *) identifier key: (NSString *) key;

- (void) read: (id <TProtocol>) inProtocol;
- (void) write: (id <TProtocol>) outProtocol;

#if TARGET_OS_IPHONE || (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
@property (nonatomic, getter=identifier, setter=setIdentifier:, strong) NSString * identifier;
@property (nonatomic, getter=key, setter=setKey:, strong) NSString * key;
#else

- (NSString *) identifier;
- (void) setIdentifier: (NSString *) identifier;

- (NSString *) key;
- (void) setKey: (NSString *) key;

#endif

- (BOOL) identifierIsSet;
- (BOOL) keyIsSet;
@end

@interface ErrorsConstants : NSObject {
}
@end
