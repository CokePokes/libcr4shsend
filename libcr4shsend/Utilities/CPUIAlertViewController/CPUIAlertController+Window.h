//
//  UIAlertController+Window.h
//  FFM
//
//  Created by Eric Larson on 6/17/15.
//  Copyright (c) 2015 ForeFlight, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPUIAlertController :  UIAlertController

- (void)show;
- (void)show:(BOOL)animated;

@property (nonatomic, strong) UIWindow *alertWindow;


@end
