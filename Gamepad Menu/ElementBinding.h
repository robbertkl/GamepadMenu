//
//  ElementBinding.h
//  Gamepad Menu
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>

@interface ElementBinding : NSObject
- (id)initWithElement:(IOHIDElementRef)element keyBindings:(NSArray *)keyBindings options:(NSDictionary *)options;
- (void)updateValue:(CFIndex)value;
@property (nonatomic, readonly) IOHIDElementRef element;
@property (nonatomic, readonly) IOHIDDeviceRef device;
@property (nonatomic, readonly) BOOL isAssigned;
@end
