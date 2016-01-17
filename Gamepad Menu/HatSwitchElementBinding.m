//
//  HatSwitchElementBinding.m
//  Gamepad Menu
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import "HatSwitchElementBinding.h"

enum {
    HatSwitchElementBindingRegionNone   = 0,
    HatSwitchElementBindingRegionFirst  = 1 << 0,
    HatSwitchElementBindingRegionSecond = 1 << 1,
    HatSwitchElementBindingRegionThird  = 1 << 2,
    HatSwitchElementBindingRegionFourth = 1 << 3,
};
typedef NSUInteger HatSwitchElementBindingRegion;

@interface HatSwitchElementBinding () {
    double _scale;
}

@end

@implementation HatSwitchElementBinding

- (id)initWithElement:(IOHIDElementRef)element keyBindings:(NSArray *)keyBindings options:(NSDictionary *)options {
    // An element of type "Hat Switch" should have 4 key binding
    keyBindings = [keyBindings subarrayWithRange:NSMakeRange(0, 4)];
    
    self = [super initWithElement:element keyBindings:keyBindings options:options];
    if (self) {
        CFIndex elementMin = IOHIDElementGetLogicalMin(element);
        CFIndex elementMax = IOHIDElementGetLogicalMax(element);
        _scale = (elementMax - elementMin) / 7.0;
    }
    return self;
}

- (NSUInteger)keyStatesForValue:(CFIndex)value {
    switch((NSUInteger)(value / _scale + 0.5)) {
        case 0: return HatSwitchElementBindingRegionFirst;
        case 1: return HatSwitchElementBindingRegionFirst | HatSwitchElementBindingRegionSecond;
        case 2: return HatSwitchElementBindingRegionSecond;
        case 3: return HatSwitchElementBindingRegionSecond | HatSwitchElementBindingRegionThird;
        case 4: return HatSwitchElementBindingRegionThird;
        case 5: return HatSwitchElementBindingRegionThird | HatSwitchElementBindingRegionFourth;
        case 6: return HatSwitchElementBindingRegionFourth;
        case 7: return HatSwitchElementBindingRegionFourth | HatSwitchElementBindingRegionFirst;
        default: return HatSwitchElementBindingRegionNone;
    }
}

@end
