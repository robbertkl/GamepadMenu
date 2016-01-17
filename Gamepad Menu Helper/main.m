//
//  main.m
//  Gamepad Menu Helper
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    AppDelegate *delegate = [[AppDelegate alloc] init];
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
}
