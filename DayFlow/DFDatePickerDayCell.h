#import <UIKit/UIKit.h>
#import "DayFlow.h"

@interface DFDatePickerDayCell : UICollectionViewCell

@property (nonatomic, readwrite, assign) DFDatePickerDate date;
@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic, readwrite, assign) BOOL showOpenDay;
@property (nonatomic, readwrite, assign) BOOL showTour;
@property (nonatomic, readwrite, assign) BOOL showInterview;

- (void) hideAllIndicator;

@end
