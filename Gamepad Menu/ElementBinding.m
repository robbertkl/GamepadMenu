//
//  ElementBinding.m
//  Gamepad Menu
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import "ElementBinding.h"

@interface ElementBinding () {
    NSArray *_keyBindings;
    NSUInteger _keyStates;
}

- (NSUInteger)keyStatesForValue:(CFIndex)value;

@end

@implementation ElementBinding

- (id)initWithElement:(IOHIDElementRef)element keyBindings:(NSArray *)keyBindings options:(NSDictionary *)options {
    self = [super init];
    if (self) {
        _element = element;
        _device = IOHIDElementGetDevice(element);
        _keyBindings = keyBindings;
        _keyStates = 0;

        _isAssigned = NO;
        for (id keyBinding in _keyBindings) {
            if ([keyBinding isKindOfClass:[NSNumber class]]) {
                _isAssigned = YES;
                break;
            }
        }
    }
    return self;
}

- (NSUInteger)keyStatesForValue:(CFIndex)value {
    // Override this in a subclass
    return 0;
}

- (void)updateValue:(CFIndex)value {
    if (!_isAssigned) return;
    
    NSUInteger newKeyStates = [self keyStatesForValue:value];
    
    NSUInteger numberOfKeyBindings = _keyBindings.count;
    for (NSUInteger index = 0; index < numberOfKeyBindings; index++) {
        id keyBinding = _keyBindings[index];
        if (![keyBinding isKindOfClass:[NSNumber class]]) continue;
        
        NSUInteger mask = 1 << index;
        BOOL isDownBefore = _keyStates & mask;
        BOOL isDownAfter = newKeyStates & mask;
        if (isDownBefore != isDownAfter) {
            [self keyboardAction:[keyBinding shortValue] pressDown:isDownAfter];
        }
    }
    
    _keyStates = newKeyStates;
}

- (void)keyboardAction:(CGKeyCode)key pressDown:(BOOL)down {
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
    CGEventRef event = CGEventCreateKeyboardEvent(source, key, down);
    CGEventPost(kCGHIDEventTap, event);
    CFRelease(event);
    CFRelease(source);
}

@end
