//
//  UIAlertController+Window.m
//  FFM
//
//  Created by Eric Larson on 6/17/15.
//  Copyright (c) 2015 ForeFlight, LLC. All rights reserved.
//

#import "CPUIAlertController+Window.h"
#import <objc/runtime.h>


@implementation CPUIAlertController

@dynamic alertWindow;

- (void)setAlertWindow:(UIWindow *)alertWindow {
    objc_setAssociatedObject(self, @selector(alertWindow), alertWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIWindow *)alertWindow {
    return objc_getAssociatedObject(self, @selector(alertWindow));
}

- (void)show {
    [self show:YES];
}

- (void)show:(BOOL)animated {
    self.alertWindow = [[NSClassFromString(@"UIWindow") alloc] initWithFrame:[NSClassFromString(@"UIScreen") mainScreen].bounds];
    self.alertWindow.rootViewController = [[NSClassFromString(@"UIViewController") alloc] init];
    self.alertWindow.windowLevel = UIWindowLevelStatusBar + 1;
    [self.alertWindow makeKeyAndVisible];
    [self.alertWindow.rootViewController presentViewController:(UIAlertController*)self animated:animated completion:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // precaution to insure window gets destroyed
    self.alertWindow.hidden = YES;
    self.alertWindow = nil;
}

@end
