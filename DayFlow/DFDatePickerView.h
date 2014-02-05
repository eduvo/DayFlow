#import <UIKit/UIKit.h>

@class DFDatePickerView, DFDatePickerDayCell;
@protocol DFDatePickerViewDelegate <NSObject>

- (void) datePickerView:(DFDatePickerView *)datePickerView willDisplayCell:(DFDatePickerDayCell *) cell withDate:(NSDate *) date atIndexPath:(NSIndexPath *)indexPath;
- (void) datePickerView:(DFDatePickerView *)datePickerView didSelectDate:(NSDate *)date;
- (void) datePickerView:(DFDatePickerView *)datePickerView didDeselectDate:(NSDate *)date;

@end

@interface DFDatePickerView : UIView

- (instancetype) initWithCalendar:(NSCalendar *)calendar;

@property (nonatomic, readwrite, strong) NSDate *selectedDate;
@property (nonatomic, readwrite, weak) id<DFDatePickerViewDelegate> delegate;

- (void) displayDate: (NSDate *) date;
- (void) reloadData;

@end
