#import <UIKit/UIKit.h>

@class DFDatePickerView, DFDatePickerDayCell;
@protocol DFDatePickerViewDelegate <NSObject>

- (void)datePickerViewDidEndDecelerating:(DFDatePickerView *)pickerView;
- (void)datePickerViewDidEndDragging:(DFDatePickerView *)pickerView willDecelerate:(BOOL)decelerate;
- (void) datePickerView:(DFDatePickerView *)datePickerView willDisplayCell:(DFDatePickerDayCell *) cell withDate:(NSDate *) date atIndexPath:(NSIndexPath *)indexPath;
- (void) datePickerView:(DFDatePickerView *)datePickerView didSelectDate:(NSDate *)date;
- (void) datePickerView:(DFDatePickerView *)datePickerView didDeselectDate:(NSDate *)date;
- (void) didDisplayDate: (NSDate *) date;

@end

@interface DFDatePickerView : UIView

- (instancetype) initWithCalendar:(NSCalendar *)calendar;

@property (nonatomic, readwrite, strong) NSDate *selectedDate;
@property (nonatomic, readwrite, weak) id<DFDatePickerViewDelegate> delegate;
@property (nonatomic, readwrite, assign) CGRect collectionBounds;
@property (nonatomic, readwrite, assign) BOOL selectable;

- (void) displayDate: (NSDate *) date;
- (NSArray *) visibleDates;
- (void) reloadData;

@end
