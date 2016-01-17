//
//  PresetMenuItem.m
//  Gamepad Menu
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import "PresetMenuItem.h"

#import <Carbon/Carbon.h>

#import "AxisElementBinding.h"
#import "ButtonElementBinding.h"
#import "HatSwitchElementBinding.h"

static NSString *const kDeviceProfileTitleKey = @"Title";
static NSString *const kDeviceProfileElementsKey = @"Elements";
static NSString *const kDeviceProfileElementTypeKey = @"Type";
static NSString *const kDeviceProfileElementBindingKey = @"Binding";

static NSString *const kElementTypeAxis = @"Axis";
static NSString *const kElementTypeButton = @"Button";
static NSString *const kElementTypeHatSwitch = @"Hat Switch";

@interface PresetMenuItem () {
    IOHIDDeviceRef _device;
    NSDictionary *_deviceProfile;
    NSDictionary *_preset;
}

@end

@implementation PresetMenuItem

- (id)initWithDevice:(IOHIDDeviceRef)device deviceProfile:(NSDictionary *)deviceProfile preset:(NSDictionary *)preset {
    self = [super init];
    if (self) {
        _device = device;
        _deviceProfile = deviceProfile;
        _preset = preset;
        
        self.title = preset[kDeviceProfileTitleKey];
        self.target = self;
        self.action = @selector(activatePreset);
        self.state = NSOffState;
    }
    return self;
}

+ (PresetMenuItem *)disabledMenuItem:(IOHIDDeviceRef)device {
    NSString *title = NSLocalizedString(@"Disabled", @"When a gamepad device has no active game preset");
    PresetMenuItem *menuItem = [[PresetMenuItem alloc] initWithDevice:device deviceProfile:@{} preset:@{ @"Title": title }];
    menuItem.state = NSOnState;
    menuItem->_disabledMenuItem = YES;
    return menuItem;
}

- (void)activatePreset {
    for (NSMenuItem *menuItem in self.menu.itemArray) {
        if ([menuItem isSeparatorItem]) continue;
        menuItem.state = NSOffState;
    }
    
    for (NSMenuItem *menuItem in self.menu.supermenu.itemArray) {
        if (menuItem.submenu == self.menu) {
            menuItem.state = _disabledMenuItem ? NSOffState : NSOnState;
        }
    }

    self.state = NSOnState;
    
    if (_delegate && [_delegate respondsToSelector:@selector(clearElementBindingsForDevice:)]) {
        [_delegate clearElementBindingsForDevice:_device];
    }
    
    NSDictionary *elementProfiles = _deviceProfile[kDeviceProfileElementsKey];
    CFArrayRef elements = IOHIDDeviceCopyMatchingElements(_device, nil, kIOHIDOptionsTypeNone);
    CFIndex elementCount = CFArrayGetCount(elements);
    for (CFIndex i = 0; i < elementCount; i++) {
        IOHIDElementRef element = (IOHIDElementRef)CFArrayGetValueAtIndex(elements, i);
        uint32_t elementUsagePage = IOHIDElementGetUsagePage(element);
        uint32_t elementUsage = IOHIDElementGetUsage(element);
        
        NSDictionary *elementProfile = elementProfiles[[NSString stringWithFormat:@"%d:%d", elementUsagePage, elementUsage]];
        if (!elementProfile) continue;
        
        Class elementBindingClass = nil;
        NSMutableArray *keyBindings = [NSMutableArray new];
        NSMutableDictionary *options = [NSMutableDictionary new];
        for (NSString *property in elementProfile) {
            id value = elementProfile[property];
            if ([property isEqualToString:kDeviceProfileElementTypeKey]) {
                if ([value isEqualToString:kElementTypeAxis]) {
                    elementBindingClass = [AxisElementBinding class];
                } else if ([value isEqualToString:kElementTypeButton]) {
                    elementBindingClass = [ButtonElementBinding class];
                } else if ([value isEqualToString:kElementTypeHatSwitch]) {
                    elementBindingClass = [HatSwitchElementBinding class];
                }
            } else if ([property isEqualToString:kDeviceProfileElementBindingKey]) {
                NSArray *bindings = [value isKindOfClass:[NSArray class]] ? value : @[value];
                for (NSString *binding in bindings) {
                    id key = [self resolveKey:_preset[binding]];
                    if (!key) key = [NSNull null];
                    [keyBindings addObject:key];
                }
            } else {
                options[property] = value;
            }
        }
        
        ElementBinding *elementBinding = [[elementBindingClass alloc] initWithElement:element keyBindings:keyBindings options:options];
        if (!elementBinding.isAssigned) continue;

        if (_delegate && [_delegate respondsToSelector:@selector(addElementBinding:)]) {
            [_delegate addElementBinding:elementBinding];
        }
    }
    CFRelease(elements);
}

- (NSNumber *)resolveKey:(id)key {
    static NSMutableDictionary *mapping;
    
    if ([key isKindOfClass:[NSString class]]) {
        if (!mapping) {
            mapping = [NSMutableDictionary new];
            
            TISInputSourceRef inputSource = TISCopyCurrentKeyboardInputSource();
            CFDataRef layoutData = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData);
            const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
            CFRelease(inputSource);
            
            for (CGKeyCode keyCode = 0; keyCode < 128; keyCode++) {
                UInt32 deadKeyState = 0;
                UniCharCount maxStringLength = 255;
                UniCharCount actualStringLength = 0;
                UniChar unicodeString[maxStringLength];
                OSStatus status = UCKeyTranslate(keyboardLayout, keyCode, kUCKeyActionDown, 0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, maxStringLength, &actualStringLength, unicodeString);
                if (actualStringLength == 0 && deadKeyState) {
                    status = UCKeyTranslate(keyboardLayout, kVK_Space, kUCKeyActionDown, 0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, maxStringLength, &actualStringLength, unicodeString);
                }

                if (status == noErr && actualStringLength > 0) {
                    NSString *character = [[NSString stringWithCharacters:unicodeString length:(NSUInteger)actualStringLength] lowercaseString];
                    if (!mapping[character]) mapping[character] = @(keyCode);
                }
            }
        }

        return mapping[[key lowercaseString]];
    }
    
    return [key isKindOfClass:[NSNumber class]] ? key : nil;
}

@end
