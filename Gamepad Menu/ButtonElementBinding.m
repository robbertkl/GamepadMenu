//
//  ButtonElementBinding.m
//  Gamepad Menu
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import "ButtonElementBinding.h"

static NSString *const kButtonElementBindingOptionsThresholdKey = @"Threshold";
static NSString *const kButtonElementBindingOptionsThresholdStickinessKey = @"ThresholdStickiness";

enum {
    ButtonElementBindingStateOff = 0,
    ButtonElementBindingStateOn  = 1,
};
typedef NSUInteger ButtonElementBindingState;

@interface ButtonElementBinding () {
    CFIndex _thresholdA;
    CFIndex _thresholdB;
    CFIndex _thresholdC;

    BOOL _isSticking;
    ButtonElementBindingState _previousState;
}

@end

@implementation ButtonElementBinding

- (id)initWithElement:(IOHIDElementRef)element keyBindings:(NSArray *)keyBindings options:(NSDictionary *)options {
    // An element of type "Button" should have 1 key binding
    keyBindings = [keyBindings subarrayWithRange:NSMakeRange(0, 1)];
    
    self = [super initWithElement:element keyBindings:keyBindings options:options];
    if (self) {
        CFIndex elementMin = IOHIDElementGetLogicalMin(element);
        CFIndex elementMax = IOHIDElementGetLogicalMax(element);
        CFIndex range = elementMax - elementMin;

        NSNumber *threshold = options[kButtonElementBindingOptionsThresholdKey];
        if (!threshold) threshold = @(0.8);
        
        NSNumber *stickiness = options[kButtonElementBindingOptionsThresholdStickinessKey];
        if (!stickiness) stickiness = @(0.0);
        
        _thresholdA = elementMin + ceil(range * (threshold.doubleValue - stickiness.doubleValue / 2));
        _thresholdB = elementMin + ceil(range * threshold.doubleValue);
        _thresholdC = elementMin + ceil(range * (threshold.doubleValue + stickiness.doubleValue / 2));
        
        _thresholdA = MIN(MAX(_thresholdA, elementMin + 1), elementMax);
        _thresholdB = MIN(MAX(_thresholdB, elementMin + 1), elementMax);
        _thresholdC = MIN(MAX(_thresholdC, elementMin + 1), elementMax);

        _isSticking = NO;
        _previousState = ButtonElementBindingStateOff;
    }
    return self;
}

- (NSUInteger)keyStatesForValue:(CFIndex)value {
    ButtonElementBindingState state = ButtonElementBindingStateOff;

    if (value < _thresholdA) {
        _isSticking = NO;
        state = ButtonElementBindingStateOff;
    } else if (value < _thresholdB) {
        state = _isSticking ? _previousState : ButtonElementBindingStateOff;
        if (state != _previousState) _isSticking = YES;
    } else if (value < _thresholdC) {
        state = _isSticking ? _previousState : ButtonElementBindingStateOn;
        if (state != _previousState) _isSticking = YES;
    } else {
        _isSticking = NO;
        state = ButtonElementBindingStateOn;
    }

    _previousState = state;
    return state;
}

@end
