//
//  AxisElementBinding.m
//  Gamepad Menu
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import "AxisElementBinding.h"

static NSString *const kAxisElementBindingOptionsThresholdKey = @"Threshold";
static NSString *const kAxisElementBindingOptionsThresholdStickinessKey = @"ThresholdStickiness";

enum {
    AxisElementBindingRegionNone = 0,
    AxisElementBindingRegionLow  = 1 << 0,
    AxisElementBindingRegionHigh = 1 << 1,
};
typedef NSUInteger AxisElementBindingRegion;

@interface AxisElementBinding () {
    CFIndex _thresholdA;
    CFIndex _thresholdB;
    CFIndex _thresholdC;
    CFIndex _thresholdD;
    CFIndex _thresholdE;
    CFIndex _thresholdF;
    
    BOOL _isStickingLow;
    BOOL _isStickingHigh;
    AxisElementBindingRegion _previousState;
}

@end

@implementation AxisElementBinding

- (id)initWithElement:(IOHIDElementRef)element keyBindings:(NSArray *)keyBindings options:(NSDictionary *)options {
    // An element of type "Axis" should have 2 key bindings
    keyBindings = [keyBindings subarrayWithRange:NSMakeRange(0, 2)];

    self = [super initWithElement:element keyBindings:keyBindings options:options];
    if (self) {
        CFIndex elementMin = IOHIDElementGetLogicalMin(element);
        CFIndex elementMax = IOHIDElementGetLogicalMax(element);
        CFIndex elementCenter = elementMin + ceil((elementMax - elementMin) / 2.0);
        CFIndex rangeLow = elementCenter - elementMin;
        CFIndex rangeHigh = elementMax - elementCenter;

        NSNumber *threshold = options[kAxisElementBindingOptionsThresholdKey];
        if (!threshold) threshold = @(0.4);

        NSNumber *stickiness = options[kAxisElementBindingOptionsThresholdStickinessKey];
        if (!stickiness) stickiness = @(0.0);

        _thresholdA = elementCenter + 1 - ceil(rangeLow * (threshold.doubleValue + stickiness.doubleValue / 2));
        _thresholdB = elementCenter + 1 - ceil(rangeLow * threshold.doubleValue);
        _thresholdC = elementCenter + 1 - ceil(rangeLow * (threshold.doubleValue - stickiness.doubleValue / 2));
        _thresholdD = elementCenter + 0 + ceil(rangeHigh * (threshold.doubleValue - stickiness.doubleValue / 2));
        _thresholdE = elementCenter + 0 + ceil(rangeHigh * threshold.doubleValue);
        _thresholdF = elementCenter + 0 + ceil(rangeHigh * (threshold.doubleValue + stickiness.doubleValue / 2));
        
        _thresholdA = MIN(MAX(_thresholdA, elementMin + 1), elementCenter);
        _thresholdB = MIN(MAX(_thresholdB, elementMin + 1), elementCenter);
        _thresholdC = MIN(MAX(_thresholdC, elementMin + 1), elementCenter);
        _thresholdD = MIN(MAX(_thresholdD, elementCenter + 1), elementMax);
        _thresholdE = MIN(MAX(_thresholdE, elementCenter + 1), elementMax);
        _thresholdF = MIN(MAX(_thresholdF, elementCenter + 1), elementMax);
        
        _isStickingLow = NO;
        _isStickingHigh = NO;
        _previousState = AxisElementBindingRegionNone;
    }
    return self;
}

- (NSUInteger)keyStatesForValue:(CFIndex)value {
    AxisElementBindingRegion state = AxisElementBindingRegionNone;

    if (value < _thresholdA) {
        state = AxisElementBindingRegionLow;
        _isStickingLow = _isStickingHigh = NO;
    } else if (value < _thresholdB) {
        state = _isStickingLow ? _previousState : AxisElementBindingRegionLow;
        if (state != _previousState) _isStickingLow = YES;
        _isStickingHigh = NO;
    } else if (value < _thresholdC) {
        state = _isStickingLow ? _previousState : AxisElementBindingRegionNone;
        if (state != _previousState) _isStickingLow = YES;
        _isStickingHigh = NO;
    } else if (value < _thresholdD) {
        state = AxisElementBindingRegionNone;
        _isStickingLow = _isStickingHigh = NO;
    } else if (value < _thresholdE) {
        state = _isStickingHigh ? _previousState : AxisElementBindingRegionNone;
        if (state != _previousState) _isStickingHigh = YES;
        _isStickingLow = NO;
    } else if (value < _thresholdF) {
        state = _isStickingHigh ? _previousState : AxisElementBindingRegionHigh;
        if (state != _previousState) _isStickingHigh = YES;
        _isStickingLow = NO;
    } else {
        state = AxisElementBindingRegionHigh;
        _isStickingLow = _isStickingHigh = NO;
    }
    
    _previousState = state;
    return state;
}

@end
