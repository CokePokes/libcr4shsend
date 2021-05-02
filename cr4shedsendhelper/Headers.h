//
//  Header.h
//  cr4shedsendhelper
//
//  Created by CokePokes on 5/1/21.
//

#import <UIKit/UIKit.h>

@interface UIImage (Private)
+(UIImage*)imageNamed:(NSString*)name inBundle:(NSBundle*)bundle;
@end

@interface UIImage (UIKitImage)
+(UIImage*)uikitImageNamed:(NSString*)name;
-(UIImage*)resizeToWidth:(CGFloat)newWidth;
-(UIImage*)resizeToHeight:(CGFloat)newHeight;
@end

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

@interface FRPSettings : NSObject
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSString *fileSave;
+ (instancetype)settingsWithKey:(NSString *)key defaultValue:(id)defaultValue;
@end

typedef void (^FRPSwitchCellChanged)(UISwitch *sender);
@interface FRPSwitchCell : FRPCell
@property (nonatomic, strong) UISwitch *switchView;
+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting postNotification:(NSString *)notification changeBlock:(FRPSwitchCellChanged)block;
@end

typedef void (^FRPSegmentValueChanged)(NSString *value);
@interface FRPSegmentCell : FRPCell
+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting items:(NSArray *)items postNotification:(NSString *)notification changeBlock:(FRPSegmentValueChanged)block __attribute__((deprecated("use instead +cellWithTitle:setting:values:displayedValues:postNotification:changeBlock")));

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting values:(NSArray *)values displayedValues:(NSArray *)displayedValues postNotification:(NSString *)notification changeBlock:(FRPSegmentValueChanged)block;
+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting values:(NSArray *)values postNotification:(NSString *)notification changeBlock:(FRPSegmentValueChanged)block;
@end

@interface FRPreferences : UITableViewController
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSString *plistPath;
+ (instancetype)tableWithSections:(NSArray *)sections title:(NSString *)title tintColor:(UIColor *)color;
- (instancetype)initTableWithSections:(NSArray *)sections;
@end

@interface CRASettingsViewController : FRPreferences
+(instancetype)newSettingsController;
-(void)updatePrefsWithKey:(NSString*)key value:(id)value;
@end
