//
//  AppDelegate.m
//  Gamepad Menu Helper
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSString *appPath = [[[[[[NSBundle mainBundle] bundlePath]
                            stringByDeletingLastPathComponent]
                           stringByDeletingLastPathComponent]
                          stringByDeletingLastPathComponent]
                         stringByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    [NSApp terminate:nil];
}

@end
