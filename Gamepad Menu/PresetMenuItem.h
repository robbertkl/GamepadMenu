//
//  PresetMenuItem.h
//  Gamepad Menu
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/hid/IOHIDLib.h>

#import "ElementBinding.h"

@protocol PresetMenuItemDelegate <NSObject>
- (void)clearElementBindingsForDevice:(IOHIDDeviceRef)device;
- (void)addElementBinding:(ElementBinding *)elementBinding;
@end

@interface PresetMenuItem : NSMenuItem
- (id)initWithDevice:(IOHIDDeviceRef)device deviceProfile:(NSDictionary *)deviceProfile preset:(NSDictionary *)preset;
+ (PresetMenuItem *)disabledMenuItem:(IOHIDDeviceRef)device;
@property (getter=isDisabledMenuItem, readonly) BOOL disabledMenuItem;
@property (nonatomic, weak) id<PresetMenuItemDelegate> delegate;
@end
