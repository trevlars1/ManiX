//
//  GBAEmulatorBridge.h
//  ManicEmu
//
//  Created by Riley Testut on 6/3/16.
//  Copyright © 2016 Riley Testut. All rights reserved.
//
//  Created by Aushuang Lee on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.

#import <Foundation/Foundation.h>

@protocol MANCEmulatorBase;

NS_ASSUME_NONNULL_BEGIN

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Silence "Cannot find protocol definition" warning due to forward declaration.
@interface GBAEmulatorBridge : NSObject <MANCEmulatorBase>
#pragma clang diagnostic pop

@property (class, nonatomic, readonly) GBAEmulatorBridge *sharedBridge;

@end

NS_ASSUME_NONNULL_END
