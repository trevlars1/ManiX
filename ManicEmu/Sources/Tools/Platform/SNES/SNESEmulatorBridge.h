//
//  SNESEmulatorBridge.h
//  ManicEmu
//
//  Created by Riley Testut on 9/12/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//
//  Created by Aushuang Lee on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.

#import <Foundation/Foundation.h>

@protocol MANCEmulatorBase;

NS_ASSUME_NONNULL_BEGIN

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Silence "Cannot find protocol definition" warning due to forward declaration.
@interface SNESEmulatorBridge : NSObject <MANCEmulatorBase>
#pragma clang diagnostic pop

@property (class, nonatomic, readonly) SNESEmulatorBridge *sharedBridge;

@end

NS_ASSUME_NONNULL_END
