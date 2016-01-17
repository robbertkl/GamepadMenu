//
//  AppDelegate.h
//  Gamepad Menu
//
//  Created by Robbert Klarenbeek on 12/01/16.
//  Copyright © 2016 Robbert Klarenbeek. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (assign) IBOutlet NSMenu *menu;
@property (nonatomic, strong) NSStatusItem *statusItem;
@end

