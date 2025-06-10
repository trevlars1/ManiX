// N64ObjC.h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface N64ObjC : NSObject

+ (instancetype)sharedInstance;

- (void)startup;
- (void)loadROM:(NSString *)path;
- (void)runFrame;
- (void)shutdown;

@end

NS_ASSUME_NONNULL_END
