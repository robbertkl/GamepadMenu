//
//  GamepadManager.h
//  Gamepad Menu
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>

@protocol GamepadManagerDelegate <NSObject>
@optional
- (void)deviceDidConnect:(IOHIDDeviceRef)device;
- (void)deviceDidDisconnect:(IOHIDDeviceRef)device;
- (void)deviceDidChange:(IOHIDValueRef)value;
@end

@interface GamepadManager : NSObject
@property (nonatomic, weak) id<GamepadManagerDelegate> delegate;
@end
