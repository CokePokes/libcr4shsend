// See http://iphonedevwiki.net/index.php/Logos

#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>
@interface FRPSection : UITableViewCell
@property (nonatomic, strong) NSString *headerTitle;
@property (nonatomic, strong) NSString *footerTitle;
@property (nonatomic, strong) NSMutableArray *cells;
@property (nonatomic, strong) UIColor *tintUIColor;
+ (instancetype)sectionWithTitle:(NSString *)title footer:(NSString *)footer;
- (void)addCell:(UITableViewCell *)cell;
- (void)addCells:(NSArray *)cells;
@end
@interface FRPCell : UITableViewCell
@end
typedef void (^FRPLinkCellSelected)(UITableViewCell *sender);
@interface FRPLinkCell : FRPCell
+ (instancetype)cellWithTitle:(NSString *)title selectedBlock:(FRPLinkCellSelected)block;
@end

@interface FRPreferences : UITableViewController
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSString *plistPath;
+ (instancetype)tableWithSections:(NSArray *)sections title:(NSString *)title tintColor:(UIColor *)color;
- (instancetype)initTableWithSections:(NSArray *)sections;
@end

@implementation FRPreferences

@end

@interface CRASettingsViewController : FRPreferences
+(instancetype)newSettingsController;
-(void)updatePrefsWithKey:(NSString*)key value:(id)value;
@end

@implementation CRASettingsViewController (loader)

@end


/*@interface CPCRATweakSettingsVC : FRPreferences

@end


@implementation CPCRATweakSettingsVC

-(instancetype)initTableWithSections:(NSArray*)sections {
    if ((self = [super initTableWithSections:sections])){
        UIImage* itemImg = [[objc_getClass("UIImage") uikitImageNamed:@"BackgroundTask_settings"] resizeToWidth:25.];
        self.tabBarItem = [[objc_getClass("UITabBarItem") alloc] initWithTitle:self.title image:itemImg tag:0];
    }
    return self;
}

-(void)loadView {
    [super loadView];
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setPrefersLargeTitles:)])
        self.navigationController.navigationBar.prefersLargeTitles = YES;
}

-(void)viewDidAppear:(BOOL)arg1 {
    //[super viewDidAppear:arg1];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}
@end*/

/*
%subclass CPCRATweakSettingsVC : FRPreferences

%new
-(instancetype)initTableWithSections:(NSArray*)sections {
    if ((self = [super initTableWithSections:sections])){
        UIImage* itemImg = [[objc_getClass("UIImage") uikitImageNamed:@"BackgroundTask_settings"] resizeToWidth:25.];
        self.tabBarItem = [[objc_getClass("UITabBarItem") alloc] initWithTitle:self.title image:itemImg tag:0];
    }
    return self;
}

-(void)loadView {
    [super loadView];
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setPrefersLargeTitles:)])
        self.navigationController.navigationBar.prefersLargeTitles = YES;
}

-(void)viewDidAppear:(BOOL)arg1 {
    //[super viewDidAppear:arg1];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

%end*/


%group Tweak

%hook CRASettingsViewController
+ (id)tableWithSections:(NSArray*)sections title:(NSString*)title tintColor:(id)color {

    NSMutableArray *newSections = sections.mutableCopy;
    FRPSection *tweakSection = [objc_getClass("FRPSection") sectionWithTitle:@"Automatic Reports" footer:@"@CokePokes"];
    [tweakSection addCell:[objc_getClass("FRPLinkCell") cellWithTitle:@"Requested Tweaks" selectedBlock:^(id sender) {
        [[(FRPreferences*)self navigationController] pushViewController:[objc_getClass("CPCRATweakSettingsVC") new] animated:YES];
    }]];
    
    [newSections addObject:tweakSection]
	return %orig(sections, title, color);
}


%end //end hook
%end //end group



/*
 CHDeclareClass(CRASettingsViewController);
 CHOptimizedClassMethod3(self, id, CRASettingsViewController, tableWithSections, NSArray*, sections, title, NSString*, title, tintColor, id, color) {
     
     NSMutableArray *newSections = sections.mutableCopy;
     FRPSection *tweakSection = [objc_getClass("FRPSection") sectionWithTitle:@"Automatic Reports" footer:@"@CokePokes"];
     [tweakSection addCell:[objc_getClass("FRPLinkCell") cellWithTitle:@"Requested Tweaks" selectedBlock:^(id sender) {
         [[(FRPreferences*)self navigationController] pushViewController:[objc_getClass("CPCRATweakSettingsVC") new] animated:YES];
     }]];
     
     [newSections addObject:tweakSection];
     
     //id orig = CHSuper3(CRASettingsViewController, tableWithSections, newSections, title, title, tintColor, color);
     return CHSuper3(CRASettingsViewController, tableWithSections, newSections, title, title, tintColor, color);
 }
 
 */

%ctor {
    @autoreleasepool {
        
        CPLog("constructor called!");
        
        if ([NSProcessInfo.processInfo.processName isEqualToString:@"Cr4shed"]){
            %init(Tweak);
        }
    }
}
