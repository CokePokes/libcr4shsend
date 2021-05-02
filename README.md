# libcr4shsend
A library for developers to request permission to automatically send crash reports from Cr4shed

`Requires libtweakemail to be installed: https://github.com/CokePokes/libtweakemail`
`Requires iOS8+ maybe lower haven't tested`

This library can be used in a sandboxed app or a regular tweak on a jailbroken device. 

How to use in your tweak/app:


NOTE: AT THIS TIME SPRINGBOARD CRASHES ARENT REPORTING YET. App and other processes report fine. 

```objc

#include <dlfcn.h>

@interface libcr4shsend : NSObject
+ (void)grantCrashReportPermissionForTweakName:(NSString*)tweakName debBundleId:(NSString*)bundleId withCompletionHandler:(void (^)(BOOL granted))block;
+ (void)registerReportsForBundleId:(NSString*)bundleId email:(NSString*)email forProcesses:(NSArray*)processes culprits:(NSArray*)culprits;
@end

- (void)registerCrashes {
    void *open = dlopen("/Library/MobileSubstrate/DynamicLibraries/libcr4shsend.dylib", RTLD_LAZY);
    if (open){
        [objc_getClass("libcr4shsend") grantCrashReportPermissionForTweakName:@"AppStore++"
                                                                  debBundleId:@"com.cokepokes.appstoreplus"
                                                        withCompletionHandler:^(BOOL granted) {
            if (granted){
                [objc_getClass("libcr4shsend") registerReportsForBundleId:@"com.cokepokes.appstoreplus"
                                                                    email:@"myemail4543f@gmail.com"
                                                             forProcesses:@[@"AppStore", @"SpringBoard"]
                                                                 culprits:@[@"appstoreplusUI.dylib", @"appstoreplusSB.dylib"]];
            }
        }];
    }
}
