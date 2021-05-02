//
//  cr4shedsendhelper.mm
//  cr4shedsendhelper
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
#include <CaptainHook/CaptainHook.h>
#include <notify.h> // not required; for examples only
#include <substrate.h>
#import "Headers.h"


@interface libtweakemail : NSObject
+ (void)sendEmailTo:(NSArray*)toArray bcc:(NSArray*)bccArray subject:(NSString*)subject body:(NSString*)body;
@end

@interface cr4shedsendhelper : NSObject
+ (NSArray*)arrayofMatchingTweakCulprit:(NSString*)culprit processName:(NSString*)processName;
@end

static NSDictionary* getInfoFromLog(NSString* logContents) { //taken from cr4shed
    if (logContents.length) {
        NSRange lastLineRange = [logContents lineRangeForRange:NSMakeRange(logContents.length - 1, 1)];
        NSString* jsonString = [logContents substringWithRange:lastLineRange];
        NSDictionary* info = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        if ([info isKindOfClass:[NSDictionary class]])
            return info;
    }
    return nil;
}

@interface CPCRATweakSettingsVC : UITableViewController
@property (nonatomic, retain) NSMutableDictionary *prefs;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView;
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section;
-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
-(void)reloadAuthorizedList;
@end

typedef void (^SwitchCompletionBlock)(UISwitch *uiSwitch);
@interface ZUISwitch : UISwitch
@property (nonatomic, copy) void (^valueChangeBlock)(UISwitch *uiSwitch);
- (void)onValueChange:(void (^)(UISwitch *uiSwitch)) block;
- (void)commonInit;
@end

CHDeclareClass(Cr4shedServer);
CHOptimizedMethod1(self, NSDictionary*, Cr4shedServer, writeString, NSDictionary*, dict){
    
    CPLog("------------- writestring called");
    
    NSString *crashlog = dict[@"string"];
    NSDictionary *info = getInfoFromLog(crashlog);
    NSString *culprit = info[@"Culprit"];
    //NSString *processBundleID = info[@"ProcessBundleID"];
    NSString *processName = info[@"ProcessName"];

    id orig = CHSuper1(Cr4shedServer, writeString, dict);
    void *open = dlopen("/Library/MobileSubstrate/DynamicLibraries/libtweakemail.dylib", RTLD_LAZY);
    if (open){
        NSArray *matchingTweaks = [cr4shedsendhelper arrayofMatchingTweakCulprit:culprit processName:processName];
        NSString *filePath = @"/private/var/mobile/Library/Preferences/com.cokepokes.libcr4shsend.plist";
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:filePath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
            dlclose(open); return orig;
        }
        for (NSString *tweakBundleId in matchingTweaks) {
            NSDictionary *tweakConfig = [prefs objectForKey:tweakBundleId];
            BOOL isAuthorized = [[tweakConfig objectForKey:@"permissionGranted"] boolValue];
            if (isAuthorized){
                [objc_getClass("libtweakemail") sendEmailTo:@[tweakConfig[@"email"]]
                                                        bcc:nil
                                                    subject:[NSString stringWithFormat:@"[Automatic] %@ Crash : %@", processName, tweakBundleId]
                                                       body:crashlog];
            }
        }
    }
    dlclose(open);
    return orig;
}


@implementation cr4shedsendhelper
+ (NSArray*)arrayofMatchingTweakCulprit:(NSString*)culprit processName:(NSString*)processName {
    NSMutableDictionary *prefs;
    NSString *filePath = @"/private/var/mobile/Library/Preferences/com.cokepokes.libcr4shsend.plist";
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        prefs = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    }
    NSMutableArray *matchingBundleIdsForCrash = @[].mutableCopy;
    NSArray *dictionaries = [prefs allValues];
    for (NSDictionary *dic in dictionaries){
        if ([dic objectForKey:@"suspects"]) {
            for (NSString*string in [dic objectForKey:@"suspects"]) {
                if ([string isEqualToString:culprit]){
                    NSArray *temp = [prefs allKeysForObject:dic];
                    NSString *key = [temp objectAtIndex:0];
                    [matchingBundleIdsForCrash addObject:key];
                }
            }
        }
        if ([dic objectForKey:@"processes"]) {
            for (NSString*string in [dic objectForKey:@"processes"]) {
                if ([string isEqualToString:culprit]){
                    NSArray *temp = [prefs allKeysForObject:dic];
                    NSString *key = [temp objectAtIndex:0];
                    [matchingBundleIdsForCrash addObject:key];
                }
            }
        }
    }
    for (NSString *str in matchingBundleIdsForCrash) {
        CPLog("matchingBundleIdsForCrash: %{public}@", str);
    }
    return matchingBundleIdsForCrash.copy;
}
@end

static NSDictionary* agetInfoFromLog(NSString* logContents) { //taken from cr4shed
    if (logContents.length) {
        NSRange lastLineRange = [logContents lineRangeForRange:NSMakeRange(logContents.length - 1, 1)];
        NSString* jsonString = [logContents substringWithRange:lastLineRange];
        NSDictionary* info = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        if ([info isKindOfClass:[NSDictionary class]])
            return info;
    }
    return nil;
}

void (*orig_writeStringToFile)(NSString *, NSString *);
MSHook(void, writeStringToFile, NSString *str, NSString *path) {
    NSDictionary *info = getInfoFromLog(str);
    NSString *culprit = info[@"Culprit"];
    NSString *processName = info[@"ProcessName"];
    //NSString *processBundleID = info[@"ProcessBundleID"];
    
    void *open = dlopen("/Library/MobileSubstrate/DynamicLibraries/libtweakemail.dylib", RTLD_LAZY);
    if (open){
        NSArray *matchingTweaks = [cr4shedsendhelper arrayofMatchingTweakCulprit:culprit processName:processName];
        NSString *filePath = @"/private/var/mobile/Library/Preferences/com.cokepokes.libcr4shsend.plist";
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:filePath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
            dlclose(open); return _writeStringToFile(str, path);
        }
        for (NSString *tweakBundleId in matchingTweaks) {
            NSDictionary *tweakConfig = [prefs objectForKey:tweakBundleId];
            BOOL isAuthorized = [[tweakConfig objectForKey:@"permissionGranted"] boolValue];
            if (isAuthorized){
                [objc_getClass("libtweakemail") sendEmailTo:@[tweakConfig[@"email"]]
                                                        bcc:nil
                                                    subject:[NSString stringWithFormat:@"[Automatic] %@ Crash : %@", processName, tweakBundleId]
                                                       body:str];
            }
        }
    }
    dlclose(open);
    _writeStringToFile(str, path);
}

CHDeclareClass(CRASettingsViewController);
CHOptimizedClassMethod3(self, id, CRASettingsViewController, tableWithSections, NSArray*, sections, title, NSString*, title, tintColor, id, color) {
    id orig = CHSuper3(CRASettingsViewController, tableWithSections, sections, title, title, tintColor, color);
    if (![NSStringFromClass(self) isEqualToString:@"CRASettingsViewController"])
        return orig;
    NSMutableArray *newSections = sections.mutableCopy;
    FRPSection *tweakSection = [objc_getClass("FRPSection") sectionWithTitle:@"Automatic Reports" footer:@"@CokePokes"];
    [tweakSection addCell:[objc_getClass("FRPLinkCell") cellWithTitle:@"Requested Tweaks" selectedBlock:^(id sender) {
        CPCRATweakSettingsVC *vc = [[objc_getClass("CPCRATweakSettingsVC") alloc] initWithNibName:nil bundle:nil];
        UITabBarController *tabCon = (UITabBarController*)[objc_getClass("UIApplication") sharedApplication].keyWindow.rootViewController;
        [tabCon.selectedViewController pushViewController:vc animated:YES];
    }]];
    [newSections addObject:tweakSection];
    return CHSuper3(CRASettingsViewController, tableWithSections, newSections, title, title, tintColor, color);
}


#pragma mark begin ZUISwitch hooks
CHDeclareClass(ZUISwitch);
CHDeclareClass(UISwitch);
CHPropertyCopyNonatomic(ZUISwitch, id, valueChangeBlock, setValueChangeBlock); //really a void not id
CHOptimizedMethod0(new, void, ZUISwitch, awakeFromNib) {
    [self commonInit];
}
CHOptimizedMethod0(new, id, ZUISwitch, init) {
    struct objc_super _super = {
        .receiver = self,
        .super_class = class_getSuperclass(self.class)
    };
    id objcSuper = objc_msgSendSuper(&_super, @selector(init));
    self = objcSuper;
    if (self) {
        [self commonInit];
    }
    return self;
}
CHOptimizedMethod0(new, void, ZUISwitch, commonInit) {
    [self addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
}
CHOptimizedMethod1(new, void, ZUISwitch, onValueChange, SwitchCompletionBlock, block) {
    self.valueChangeBlock = block;
}
CHOptimizedMethod1(new, void, ZUISwitch, switchValueChanged, id, sender) {
    if(self.valueChangeBlock) {
        self.valueChangeBlock(self);
    }
}
#pragma mark end ZUISwitch hooks

#pragma mark begin CPCRATweakSettingsVC hooks
CHDeclareClass(UITableViewController);
CHDeclareClass(CPCRATweakSettingsVC);
CHPropertyRetainNonatomic(CPCRATweakSettingsVC, NSMutableDictionary*, prefs, setPrefs);

CHOptimizedMethod0(new, void, CPCRATweakSettingsVC, reloadAuthorizedList) {
    NSString *filePath = @"/private/var/mobile/Library/Preferences/com.cokepokes.libcr4shsend.plist";
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        self.prefs = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    } else {
        self.prefs = [NSMutableDictionary dictionary]; //new
    }
    [self.tableView reloadData];
}

CHOptimizedMethod2(new, id, CPCRATweakSettingsVC, initWithNibName, NSString*, nibNameOrNil, bundle, NSBundle*, nibBundleOrNil) {
    struct objc_super _super = {
        .receiver = self,
        .super_class = class_getSuperclass(self.class)
    };
    id objcSuper = objc_msgSendSuper(&_super, _cmd);
    
    self = [objcSuper initWithStyle:UITableViewStyleGrouped];
    if (self){
        self.title = @"Auto Email Reports";
    }
    return self;
}
CHOptimizedMethod1(new, NSInteger, CPCRATweakSettingsVC, numberOfSectionsInTableView, UITableView*, tableView) {
   return 1;
}
CHOptimizedMethod2(new, NSInteger, CPCRATweakSettingsVC, tableView, UITableView*, tableView, numberOfRowsInSection, NSInteger, section) {
    return self.prefs.allKeys.count;
}
CHOptimizedMethod2(new, NSString*, CPCRATweakSettingsVC, tableView, UITableView*, tableView, titleForHeaderInSection, NSInteger, section) {
    if (section == 0){
        return @"Authorized For Auto Emails";
    }
    return nil;
}
CHOptimizedMethod2(new, UITableViewCell*, CPCRATweakSettingsVC, tableView, UITableView*, tableView, cellForRowAtIndexPath, NSIndexPath*, indexPath) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"_cell"];
    if (!cell){
        cell = [[objc_getClass("UITableViewCell") alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"_cell"];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    cell.textLabel.text = self.prefs.allKeys[indexPath.row];
    ZUISwitch *switchEver = [[objc_getClass("ZUISwitch") alloc] init];
    cell.accessoryView = switchEver;
    NSDictionary *dicWithIn = [self.prefs objectForKey:self.prefs.allKeys[indexPath.row]];
    switchEver.on = [[dicWithIn objectForKey:@"permissionGranted"] boolValue];
    [switchEver onValueChange:^(UISwitch *uiSwitch) {
        NSMutableDictionary *newDicWithin = dicWithIn.mutableCopy;
        [newDicWithin setObject:[NSNumber numberWithBool:uiSwitch.on] forKey:@"permissionGranted"];
        [self.prefs setObject:newDicWithin forKey:self.prefs.allKeys[indexPath.row]];
        [self.prefs writeToFile:@"/private/var/mobile/Library/Preferences/com.cokepokes.libcr4shsend.plist" atomically:YES];
    }];
    return cell;
}
CHMethod0(void, CPCRATweakSettingsVC, loadView) {
    CHSuper0(CPCRATweakSettingsVC, loadView);
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setPrefersLargeTitles:)]){
        if (@available(iOS 11.0, *)) {
            self.navigationController.navigationBar.prefersLargeTitles = YES;
        }
    }
}
CHMethod0(void, CPCRATweakSettingsVC, viewDidLoad) {
    CHSuper0(CPCRATweakSettingsVC, viewDidLoad);
    [self reloadAuthorizedList];
}
CHMethod1(void, CPCRATweakSettingsVC, viewDidAppear, BOOL, animated) {
    CHSuper1(CPCRATweakSettingsVC, viewDidAppear, animated);
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}
CHMethod1(void, CPCRATweakSettingsVC, viewDidDisappear, BOOL, animated) {
    CHSuper1(CPCRATweakSettingsVC, viewDidDisappear, animated);
}
#pragma mark end CPCRATweakSettingsVC hooks


CHConstructor {
	@autoreleasepool {
        if ([NSProcessInfo.processInfo.processName isEqualToString:@"cr4shedd"]){
            CHLoadLateClass(Cr4shedServer);
            CHHook1(Cr4shedServer, writeString);
        }
        if ([NSProcessInfo.processInfo.processName isEqualToString:@"ReportCrash"]){
            MSImageRef ref = MSGetImageByName("/Library/MobileSubstrate/DynamicLibraries/Cr4shedMach.dylib");
            orig_writeStringToFile = (void (*)(NSString *, NSString *))MSFindSymbol(ref, "__Z17writeStringToFileP8NSStringS0_");
            if (orig_writeStringToFile){
                MSHookFunction(orig_writeStringToFile, MSHake(writeStringToFile));
            } else {
                CPLog("Couldn't find writeStringToFile");
            }
        }
        
        if ([NSProcessInfo.processInfo.processName isEqualToString:@"Cr4shed"]){
            CHLoadLateClass(UITableViewController);
            CHRegisterClass(CPCRATweakSettingsVC, UITableViewController) {
                CHHookProperty(CPCRATweakSettingsVC, prefs, setPrefs);
                CHHook0(CPCRATweakSettingsVC, loadView);
                CHHook0(CPCRATweakSettingsVC, viewDidLoad);
                CHHook1(CPCRATweakSettingsVC, viewDidAppear);
                CHHook1(CPCRATweakSettingsVC, viewDidDisappear);
                CHHook0(CPCRATweakSettingsVC, reloadAuthorizedList);
                CHHook2(CPCRATweakSettingsVC, initWithNibName, bundle);
                CHHook1(CPCRATweakSettingsVC, numberOfSectionsInTableView);
                CHHook2(CPCRATweakSettingsVC, tableView, numberOfRowsInSection);
                CHHook2(CPCRATweakSettingsVC, tableView, cellForRowAtIndexPath);
                CHHook2(CPCRATweakSettingsVC, tableView, titleForHeaderInSection);
            }
            CHLoadLateClass(UISwitch);
            CHRegisterClass(ZUISwitch, UISwitch) {
                CHHookProperty(ZUISwitch, valueChangeBlock, setValueChangeBlock);
                CHHook0(ZUISwitch, init);
                CHHook0(ZUISwitch, commonInit);
                CHHook0(ZUISwitch, awakeFromNib);
                CHHook1(ZUISwitch, onValueChange);
                CHHook1(ZUISwitch, switchValueChanged);
            }
            CHLoadLateClass(CRASettingsViewController);
            CHHook3(CRASettingsViewController, tableWithSections, title, tintColor);
        }
    }
}
