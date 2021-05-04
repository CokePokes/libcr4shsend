//
//  libcr4shsend.mm
//  libcr4shsend
//
//  Created by CokePokes on 4/23/21.
//  Copyright (c) 2021 ___ORGANIZATIONNAME___. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import <Foundation/Foundation.h>
#import "CaptainHook/CaptainHook.h"
#include <notify.h> // not required; for examples only
#import "CPUIAlertController+Window.h"
#include <dlfcn.h>

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter();

@interface libcr4shsend : NSObject

+ (void)grantCrashReportPermissionForTweakName:(NSString*)tweakName debBundleId:(NSString*)bundleId withCompletionHandler:(void (^)(BOOL granted))block;
+ (void)registerReportsForBundleId:(NSString*)bundleId email:(NSString*)email processes:(NSArray*)processes culprits:(NSArray*)culprits;
+ (id)shared;
@end

@implementation libcr4shsend

+ (id)shared {
    static libcr4shsend *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

+ (void)grantCrashReportPermissionForTweakName:(NSString*)tweakName debBundleId:(NSString*)bundleId withCompletionHandler:(void (^)(BOOL granted))block {
    BOOL hasRequestedForBundleId = NO;
    NSString *filePath = @"/private/var/mobile/Library/Preferences/com.cokepokes.libcr4shsend.plist";
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:filePath];
        if (prefs[bundleId]){
            hasRequestedForBundleId = YES;
        }
    }
    if (!hasRequestedForBundleId){
        CPUIAlertController *alC = [CPUIAlertController alertControllerWithTitle:@"Auto Crash Reports" message:[NSString stringWithFormat:@"The tweak: \"%@\" has requested automatic crash reports. Would you like to enable automatic crash reporting for this tweak?", tweakName] preferredStyle:UIAlertControllerStyleAlert];
        [alC addAction:[UIAlertAction actionWithTitle:@"Enable" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSDictionary *dic = @{@"bundleId": bundleId,
                                  @"tweakName": tweakName,
                                  @"permissionGranted" : [NSNumber numberWithBool:YES] };
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.cokepokes.libcr4shsend-requestPermission"), (__bridge const void *)json, NULL, true);
            block(YES);
        }]];
        [alC addAction:[UIAlertAction actionWithTitle:@"Reject" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSDictionary *dic = @{@"bundleId": bundleId,
                                  @"tweakName": tweakName,
                                  @"permissionGranted" : [NSNumber numberWithBool:NO] };
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.cokepokes.libcr4shsend-requestPermission"), (__bridge const void *)json, NULL, true);
            block(NO);
        }]];
        [alC show];
    }
}

+ (void)registerReportsForBundleId:(NSString*)bundleId email:(NSString*)email processes:(NSArray*)processes culprits:(NSArray*)culprits {
    //need bundleid for lookup
    NSMutableDictionary *targetPrefs = @{}.mutableCopy;
    if (email != NULL){ //& check if email is valid email format here prolly
        [targetPrefs setObject:email forKey:@"email"];
    } else {
        return;
    }
    if (bundleId){
        [targetPrefs setObject:bundleId forKey:@"bundleId"];
    }
    if (processes){
        [targetPrefs setObject:processes forKey:@"processes"];
    }
    if (culprits){
        [targetPrefs setObject:culprits forKey:@"culprits"];
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:targetPrefs.copy options:NSJSONWritingPrettyPrinted error:nil];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.cokepokes.libcr4shsend-registerReports"), (__bridge const void *)json, NULL, true);
}
@end

static void requestPermissionForAuto(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSData *data = [(__bridge NSString *)object dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *passedDic = [[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil] mutableCopy];

    NSMutableDictionary *prefs;
    NSString *filePath = @"/private/var/mobile/Library/Preferences/com.cokepokes.libcr4shsend.plist";
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        prefs = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    } else {
        prefs = [NSMutableDictionary dictionary]; //new
    }
    
    NSMutableDictionary *targetPrefs;
    if (prefs[passedDic[@"bundleId"]]){
        targetPrefs = [prefs[passedDic[@"bundleId"]] mutableCopy];
    } else {
        targetPrefs = @{}.mutableCopy;
    }
    NSString *passedBundleId = passedDic[@"bundleId"];
    BOOL passedPermissionStatus = [passedDic[@"permissionGranted"] boolValue];

    [targetPrefs setObject:[NSNumber numberWithBool:passedPermissionStatus] forKey:@"permissionGranted"];
    
    [prefs setObject:targetPrefs.copy forKey:passedBundleId];
    [prefs.copy writeToFile:filePath atomically:YES];
}

static void registerReports(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSData *data = [(__bridge NSString *)object dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *passedDic = [[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil] mutableCopy];
    
    NSMutableDictionary *prefs;
    NSString *filePath = @"/private/var/mobile/Library/Preferences/com.cokepokes.libcr4shsend.plist";
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        prefs = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    } else {
        prefs = [NSMutableDictionary dictionary]; //new
    }
    
    NSMutableDictionary *targetPrefs;
    if (prefs[passedDic[@"bundleId"]]){
        targetPrefs = [prefs[passedDic[@"bundleId"]] mutableCopy];
    } else {
        targetPrefs = @{}.mutableCopy;
    }
    
    if (passedDic[@"email"] != NULL){ //& check if email is valid email format here too
        [targetPrefs setObject:passedDic[@"email"] forKey:@"email"];
    }
    if (passedDic[@"processes"]){
        [targetPrefs setObject:passedDic[@"processes"] forKey:@"processes"];
    }
    if (passedDic[@"culprits"]){
        [targetPrefs setObject:passedDic[@"culprits"] forKey:@"culprits"];
    }
        
    [prefs setObject:targetPrefs.copy forKey:passedDic[@"bundleId"]];
    [prefs.copy writeToFile:filePath atomically:YES];
}

CHConstructor {
    @autoreleasepool {
        if ([NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"]){ //only want springboard to run server
            void *handle = dlopen("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation", RTLD_LAZY);
            void *impl = NULL;
            if (handle) {
                impl = dlsym(handle, "CFNotificationCenterGetDistributedCenter");
            }
            if (impl) {
                CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),
                                                NULL,
                                                requestPermissionForAuto,
                                                CFSTR("com.cokepokes.libcr4shsend-requestPermission"),
                                                NULL,
                                                CFNotificationSuspensionBehaviorDeliverImmediately);
                
                CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),
                                                NULL,
                                                registerReports,
                                                CFSTR("com.cokepokes.libcr4shsend-registerReports"),
                                                NULL,
                                                CFNotificationSuspensionBehaviorDeliverImmediately);
            }
        }
    }
}
