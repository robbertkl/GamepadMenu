//
//  AppDelegate.m
//  Gamepad Menu
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import "AppDelegate.h"

#import "ElementBinding.h"
#import "GamepadManager.h"
#import "PresetMenuItem.h"

static NSString *const kStatusMenuTemplateName = @"StatusMenuTemplate";

static NSString *const kDeviceProfilesDirectory = @"Device Profiles";
static NSString *const kPresetsDirectory = @"Presets";

static NSString *const kEntityTitleKey = @"Title";
static NSString *const kDeviceProfileIdentifierKey = @"Identifier";
static NSString *const kDeviceProfileIdentifierVendorKey = @"Vendor";
static NSString *const kDeviceProfileIdentifierProductKey = @"Product";

@interface AppDelegate () <GamepadManagerDelegate, PresetMenuItemDelegate> {
    NSArray *_deviceProfiles;
    NSArray *_presets;
    
    GamepadManager *_gamepadManager;
    NSMutableDictionary *_connectedDevices;
    NSMutableDictionary *_elementBindings;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.menu = self.menu;
    _statusItem.image = [NSImage imageNamed:kStatusMenuTemplateName];
    _statusItem.highlightMode = YES;
    
    _connectedDevices = [NSMutableDictionary new];
    _elementBindings = [NSMutableDictionary new];
    
    _deviceProfiles = [self loadPlistsFromDirectory:kDeviceProfilesDirectory];
    _presets = [self loadPlistsFromDirectory:kPresetsDirectory];
    
    _gamepadManager = [GamepadManager new];
    _gamepadManager.delegate = self;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
}

- (NSArray *)loadPlistsFromDirectory:(NSString *)directory {
    NSMutableArray *items = [NSMutableArray new];
    NSBundle *bundle = [NSBundle mainBundle];
    NSArray *files = [[bundle pathsForResourcesOfType:@"plist" inDirectory:directory] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (NSString *file in files) {
        NSMutableDictionary *item = [NSMutableDictionary dictionaryWithContentsOfFile:file];
        item[kEntityTitleKey] = [[file lastPathComponent] stringByDeletingPathExtension];
        [items addObject:item];
    }
    return items;
}

- (NSMenuItem *)menuItemForDevice:(IOHIDDeviceRef)device withDeviceProfile:(NSDictionary *)deviceProfile {
    NSMenu *menu = [NSMenu new];

    for (NSDictionary *preset in _presets) {
        PresetMenuItem *menuItem = [[PresetMenuItem alloc] initWithDevice:device deviceProfile:deviceProfile preset:preset];
        menuItem.delegate = self;
        [menu addItem:menuItem];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];
    PresetMenuItem *disabledMenuItem = [PresetMenuItem disabledMenuItem:device];
    disabledMenuItem.delegate = self;
    [menu addItem:disabledMenuItem];
    
    NSMenuItem *menuItem = [NSMenuItem new];
    menuItem.title = deviceProfile[kEntityTitleKey];
    menuItem.submenu = menu;
    return menuItem;
}

- (NSMenuItem *)menuItemForUnknownDeviceWithVendor:(uint32_t)vendorId product:(uint32_t)productId {
    NSMenu *menu = [NSMenu new];

    NSMenuItem *infoItem = [NSMenuItem new];
    infoItem.title = NSLocalizedString(@"No profile exists for this device", @"Unknown device info text");
    infoItem.enabled = NO;
    [menu addItem:infoItem];
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *vendorIdItem = [NSMenuItem new];
    vendorIdItem.title = [NSString stringWithFormat:@"Vendor ID: 0x%02x", vendorId];
    vendorIdItem.enabled = NO;
    [menu addItem:vendorIdItem];
    
    NSMenuItem *productIdItem = [NSMenuItem new];
    productIdItem.title = [NSString stringWithFormat:@"Product ID: 0x%02x", productId];
    productIdItem.enabled = NO;
    [menu addItem:productIdItem];
    
    NSMenuItem *menuItem = [NSMenuItem new];
    menuItem.title = NSLocalizedString(@"Unknown Gamepad", @"Name for unknown device");
    menuItem.submenu = menu;
    return menuItem;
}

#pragma mark - PresetMenuItemDelegate

- (void)clearElementBindingsForDevice:(IOHIDDeviceRef)device {
    for (id elementHash in [_elementBindings allKeys]) {
        ElementBinding *elementBinding = _elementBindings[elementHash];
        if (elementBinding.device == device) [_elementBindings removeObjectForKey:elementHash];
    }
}

- (void)addElementBinding:(ElementBinding *)elementBinding {
    id elementHash = [NSValue valueWithPointer:elementBinding.element];
    _elementBindings[elementHash] = elementBinding;
}

#pragma mark - GamepadManagerDelegate

- (void)deviceDidConnect:(IOHIDDeviceRef)device {
    uint32_t vendorId = 0;
    CFNumberGetValue(IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey)), kCFNumberSInt32Type, &vendorId);

    uint32_t productId = 0;
    CFNumberGetValue(IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey)), kCFNumberSInt32Type, &productId);

    NSDictionary *deviceProfile;
    for (NSDictionary *deviceProfileCandidate in _deviceProfiles) {
        id identifier = deviceProfileCandidate[kDeviceProfileIdentifierKey];
        NSArray *identifierCandidates;
        if ([identifier isKindOfClass:[NSDictionary class]]) {
            identifierCandidates = @[identifier];
        } else if ([identifier isKindOfClass:[NSArray class]]) {
            identifierCandidates = identifier;
        } else {
            continue;
        }
        for (NSDictionary *identifierCandidate in identifierCandidates) {
            if (vendorId != [identifierCandidate[kDeviceProfileIdentifierVendorKey] unsignedIntegerValue]) continue;
            if (productId != [identifierCandidate[kDeviceProfileIdentifierProductKey] unsignedIntegerValue]) continue;
            deviceProfile = deviceProfileCandidate;
            break;
        }
        if (deviceProfile) break;
    }

    NSMenuItem *menuItem;
    if (!deviceProfile) {
        menuItem = [self menuItemForUnknownDeviceWithVendor:vendorId product:productId];
        deviceProfile = @{};
    } else {
        menuItem = [self menuItemForDevice:device withDeviceProfile:deviceProfile];
    }
    menuItem.tag = (NSInteger)device;
    
    NSMenuItem *placeholder = nil;
    BOOL didInsert = NO;
    for (NSMenuItem *existingMenuItem in _menu.itemArray) {
        if (existingMenuItem.isSeparatorItem) break;
        if (existingMenuItem.tag == 0) {
            placeholder = existingMenuItem;
            continue;
        }
        if (didInsert) continue;
        NSComparisonResult compare = [existingMenuItem.title caseInsensitiveCompare:menuItem.title];
        if (compare == NSOrderedAscending) continue;
        if (compare == NSOrderedSame && menuItem.tag > existingMenuItem.tag) continue;
        [_menu insertItem:menuItem atIndex:[_menu indexOfItem:existingMenuItem]];
        didInsert = YES;
    }

    if (!didInsert) [_menu insertItem:menuItem atIndex:[_menu indexOfItem:placeholder]];
    placeholder.hidden = YES;
    
    _connectedDevices[[NSValue valueWithPointer:device]] = deviceProfile;
}

- (void)deviceDidDisconnect:(IOHIDDeviceRef)device {
    [_connectedDevices removeObjectForKey:[NSValue valueWithPointer:device]];
    [self clearElementBindingsForDevice:device];
    
    NSMenuItem *placeholder = nil;
    for (NSMenuItem *existingMenuItem in _menu.itemArray) {
        if (existingMenuItem.isSeparatorItem) break;
        if (existingMenuItem.tag == 0) placeholder = existingMenuItem;
        if (existingMenuItem.tag == (NSInteger)device) [_menu removeItem:existingMenuItem];
    }

    placeholder.hidden = _connectedDevices.count > 0;
}

- (void)deviceDidChange:(IOHIDValueRef)value {
    IOHIDElementRef element = IOHIDValueGetElement(value);
    id elementHash = [NSValue valueWithPointer:element];
    ElementBinding *elementBinding = _elementBindings[elementHash];
    [elementBinding updateValue:IOHIDValueGetIntegerValue(value)];
}

@end
