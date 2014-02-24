#import <QuartzCore/QuartzCore.h>
#import "DayFlow.h"
#import "DFDatePickerCollectionView.h"
#import "DFDatePickerDayCell.h"
#import "DFDatePickerMonthHeader.h"
#import "DFDatePickerView.h"
#import "NSCalendar+DFAdditions.h"
#import "OACollectionViewFlowLayout.h"

static NSString * const DFDatePickerViewCellIdentifier = @"dateCell";
static NSString * const DFDatePickerViewMonthHeaderIdentifier = @"monthHeader";

@interface DFDatePickerView () <DFDatePickerCollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate>
@property (nonatomic, readonly, strong) NSCalendar *calendar;
@property (nonatomic, readonly, assign) DFDatePickerDate fromDate;
@property (nonatomic, readonly, assign) DFDatePickerDate toDate;
@property (nonatomic, readonly, strong) UICollectionView *collectionView;
@property (nonatomic, readonly, strong) UICollectionViewFlowLayout *collectionViewLayout;
@property (nonatomic, readonly, assign) NSInteger monthRange;
@end

@implementation DFDatePickerView
@synthesize calendar = _calendar;
@synthesize fromDate = _fromDate;
@synthesize toDate = _toDate;
@synthesize collectionView = _collectionView;
@synthesize collectionViewLayout = _collectionViewLayout;

- (instancetype) initWithCalendar:(NSCalendar *)calendar {
	
	self = [super initWithFrame:CGRectZero];
	if (self) {
		
		_calendar = calendar;
		_monthRange = 6;
		
		NSDate *now = [_calendar dateFromComponents:[_calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]]];
		
		_fromDate = [self pickerDateFromDate:[_calendar dateByAddingComponents:((^{
			NSDateComponents *components = [NSDateComponents new];
			components.month = -self.monthRange;
			return components;
		})()) toDate:now options:0]];
		
		_toDate = [self pickerDateFromDate:[_calendar dateByAddingComponents:((^{
			NSDateComponents *components = [NSDateComponents new];
			components.month = self.monthRange;
			return components;
		})()) toDate:now options:0]];
		
	}
	
	return self;
	
}

- (id) initWithFrame:(CGRect)frame {
	
	self = [self initWithCalendar:[NSCalendar currentCalendar]];
	if (self) {
		self.frame = frame;
		_monthRange = 6;
	}
	
	return self;
	
}

- (void) layoutSubviews {
	
	[super layoutSubviews];
	
	if(CGRectGetWidth(self.collectionBounds)) {
		self.collectionView.frame = self.collectionBounds;
	} else {
		self.collectionView.frame = self.bounds;
	}
	if (!self.collectionView.superview) {
		[self addSubview:self.collectionView];
	}
	
}

- (void) willMoveToSuperview:(UIView *)newSuperview {

	[super willMoveToSuperview:newSuperview];
	
	if (newSuperview && !_collectionView) {
		UICollectionView *cv = self.collectionView;
		[self displayDate: [NSDate date] animated: NO];
	}

}

- (UICollectionView *) collectionView {

	if (!_collectionView) {
		_collectionView = [[DFDatePickerCollectionView alloc] initWithFrame:self.bounds collectionViewLayout:self.collectionViewLayout];
		_collectionView.backgroundColor = [UIColor whiteColor];
		_collectionView.dataSource = self;
		_collectionView.delegate = self;
		_collectionView.showsVerticalScrollIndicator = NO;
		_collectionView.showsHorizontalScrollIndicator = NO;
		[_collectionView registerClass:[DFDatePickerDayCell class] forCellWithReuseIdentifier:DFDatePickerViewCellIdentifier];
		[_collectionView registerClass:[DFDatePickerMonthHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:DFDatePickerViewMonthHeaderIdentifier];

		[_collectionView reloadData];
	}
	
	return _collectionView;

}

- (UICollectionViewFlowLayout *) collectionViewLayout {
	
	//	Hard key these things.
	//	44 * 7 + 2 * 6 = 320; this is how the Calendar.app works
	//	and this also avoids the “one pixel” confusion which might or might not work
	//	If you need to decorate, key decorative views in.
	
	if (!_collectionViewLayout) {
		_collectionViewLayout = [OACollectionViewFlowLayout new];
//		_collectionViewLayout.headerReferenceSize = (CGSize){ 320, 64 };
//		_collectionViewLayout.itemSize = (CGSize){ 44, 44 };
//		_collectionViewLayout.minimumLineSpacing = 2.0f;
//		_collectionViewLayout.minimumInteritemSpacing = 2.0f;
		_collectionViewLayout.headerReferenceSize = (CGSize){ 680, 64 };
		_collectionViewLayout.itemSize = (CGSize){ 90, 90 };
		_collectionViewLayout.sectionInset = (UIEdgeInsets){2,10,2,10};
		_collectionViewLayout.minimumLineSpacing = 2.0f;
		_collectionViewLayout.minimumInteritemSpacing = 2.0f;

	}
	
	return _collectionViewLayout;

}

- (void) pickerCollectionViewWillLayoutSubviews:(DFDatePickerCollectionView *)pickerCollectionView {
	
	//	Note: relayout is slower than calculating 3 or 6 months’ worth of data at a time
	//	So we punt 6 months at a time.
	
	//	Running Time	Self		Symbol Name
	//
	//	1647.0ms   23.7%	1647.0	 	objc_msgSend
	//	193.0ms    2.7%	193.0	 	-[NSIndexPath compare:]
	//	163.0ms    2.3%	163.0	 	objc::DenseMap<objc_object*, unsigned long, true, objc::DenseMapInfo<objc_object*>, objc::DenseMapInfo<unsigned long> >::LookupBucketFor(objc_object* const&, std::pair<objc_object*, unsigned long>*&) const
	//	141.0ms    2.0%	141.0	 	DYLD-STUB$$-[_UIHostedTextServiceSession dismissTextServiceAnimated:]
	//	138.0ms    1.9%	138.0	 	-[NSObject retain]
	//	136.0ms    1.9%	136.0	 	-[NSIndexPath indexAtPosition:]
	//	124.0ms    1.7%	124.0	 	-[_UICollectionViewItemKey isEqual:]
	//	118.0ms    1.7%	118.0	 	_objc_rootReleaseWasZero
	//	105.0ms    1.5%	105.0	 	DYLD-STUB$$CFDictionarySetValue$shim
	
	if (pickerCollectionView.contentOffset.y < 0.0f) {
		[self appendPastDates];
	}
	
	if (pickerCollectionView.contentOffset.y > (pickerCollectionView.contentSize.height - CGRectGetHeight(pickerCollectionView.bounds))) {
		[self appendFutureDates];
	}
	
}

- (void) appendPastDates {

	[self shiftDatesByComponents:((^{
		NSDateComponents *dateComponents = [NSDateComponents new];
		dateComponents.month = -self.monthRange;
		return dateComponents;
	})())];

}

- (void) appendFutureDates {
	
	[self shiftDatesByComponents:((^{
		NSDateComponents *dateComponents = [NSDateComponents new];
		dateComponents.month = self.monthRange;
		return dateComponents;
	})())];
	
}

- (void) shiftDatesByComponents:(NSDateComponents *)components {
	
	UICollectionView *cv = self.collectionView;
	UICollectionViewFlowLayout *cvLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
	
	NSArray *visibleCells = [self.collectionView visibleCells];
	if (![visibleCells count])
		return;
	
	NSIndexPath *fromIndexPath = [cv indexPathForCell:((UICollectionViewCell *)visibleCells[0]) ];
	NSInteger fromSection = fromIndexPath.section;
	NSDate *fromSectionOfDate = [self dateForFirstDayInSection:fromSection];
	CGPoint fromSectionOrigin = [self convertPoint:[cvLayout layoutAttributesForItemAtIndexPath:fromIndexPath].frame.origin fromView:cv];
	
	_fromDate = [self pickerDateFromDate:[self.calendar dateByAddingComponents:components toDate:[self dateFromPickerDate:self.fromDate] options:0]];
	_toDate = [self pickerDateFromDate:[self.calendar dateByAddingComponents:components toDate:[self dateFromPickerDate:self.toDate] options:0]];

#if 0
	
	//	This solution trips up the collection view a bit
	//	because our reload is reactionary, and happens before a relayout
	//	since we must do it to avoid flickering and to heckle the CA transaction (?)
	//	that could be a small red flag too
	
	[cv performBatchUpdates:^{
		
		if (components.month < 0) {
			
			[cv deleteSections:[NSIndexSet indexSetWithIndexesInRange:(NSRange){
				cv.numberOfSections - abs(components.month),
				abs(components.month)
			}]];
			
			[cv insertSections:[NSIndexSet indexSetWithIndexesInRange:(NSRange){
				0,
				abs(components.month)
			}]];
			
		} else {
			
			[cv insertSections:[NSIndexSet indexSetWithIndexesInRange:(NSRange){
				cv.numberOfSections,
				abs(components.month)
			}]];
			
			[cv deleteSections:[NSIndexSet indexSetWithIndexesInRange:(NSRange){
				0,
				abs(components.month)
			}]];
			
		}
		
	} completion:^(BOOL finished) {
		
		NSLog(@"%s %x", __PRETTY_FUNCTION__, finished);
		
	}];
	
	for (UIView *view in cv.subviews)
		[view.layer removeAllAnimations];
	
#else
	
	[cv reloadData];
	[cvLayout invalidateLayout];
	[cvLayout prepareLayout];

#endif
	
	NSInteger toSection = [self.calendar components:NSMonthCalendarUnit fromDate:[self dateForFirstDayInSection:0] toDate:fromSectionOfDate options:0].month;
	UICollectionViewLayoutAttributes *toAttrs = [cvLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:toSection]];
	CGPoint toSectionOrigin = [self convertPoint:toAttrs.frame.origin fromView:cv];
	
	[cv setContentOffset:(CGPoint) {
		cv.contentOffset.x,
		cv.contentOffset.y + (toSectionOrigin.y - fromSectionOrigin.y)
	}];
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return [self.calendar components:NSMonthCalendarUnit fromDate:[self dateFromPickerDate:self.fromDate] toDate:[self dateFromPickerDate:self.toDate] options:0].month;
	
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	
	return 7 * [self numberOfWeeksForMonthOfDate:[self dateForFirstDayInSection:section]];
	
}

- (NSDate *) dateForFirstDayInSection:(NSInteger)section {

	return [self.calendar dateByAddingComponents:((^{
		NSDateComponents *dateComponents = [NSDateComponents new];
		dateComponents.month = section;
		return dateComponents;
	})()) toDate:[self dateFromPickerDate:self.fromDate] options:0];

}

- (NSUInteger) numberOfWeeksForMonthOfDate:(NSDate *)date {

	NSDate *firstDayInMonth = [self.calendar dateFromComponents:[self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:date]];
	
	NSDate *lastDayInMonth = [self.calendar dateByAddingComponents:((^{
		NSDateComponents *dateComponents = [NSDateComponents new];
		dateComponents.month = 1;
		dateComponents.day = -1;
		return dateComponents;
	})()) toDate:firstDayInMonth options:0];
	
	NSDate *fromSunday = [self.calendar dateFromComponents:((^{
		NSDateComponents *dateComponents = [self.calendar components:NSWeekOfYearCalendarUnit|NSYearForWeekOfYearCalendarUnit fromDate:firstDayInMonth];
		dateComponents.weekday = 1;
		return dateComponents;
	})())];
	
	NSDate *toSunday = [self.calendar dateFromComponents:((^{
		NSDateComponents *dateComponents = [self.calendar components:NSWeekOfYearCalendarUnit|NSYearForWeekOfYearCalendarUnit fromDate:lastDayInMonth];
		dateComponents.weekday = 1;
		return dateComponents;
	})())];
	
	return 1 + [self.calendar components:NSWeekCalendarUnit fromDate:fromSunday toDate:toSunday options:0].week;
	
}

- (DFDatePickerDayCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	DFDatePickerDayCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DFDatePickerViewCellIdentifier forIndexPath:indexPath];
	
	NSDate *firstDayInMonth = [self dateForFirstDayInSection:indexPath.section];
	DFDatePickerDate firstDayPickerDate = [self pickerDateFromDate:firstDayInMonth];
	NSUInteger weekday = [self.calendar components:NSWeekdayCalendarUnit fromDate:firstDayInMonth].weekday;
	
	NSDate *cellDate = [self.calendar dateByAddingComponents:((^{
		NSDateComponents *dateComponents = [NSDateComponents new];
		dateComponents.day = indexPath.item - (weekday - 1);
		return dateComponents;
	})()) toDate:firstDayInMonth options:0];
	DFDatePickerDate cellPickerDate = [self pickerDateFromDate:cellDate];
	
	cell.date = cellPickerDate;
	cell.enabled = ((firstDayPickerDate.year == cellPickerDate.year) && (firstDayPickerDate.month == cellPickerDate.month));
	
	[self highlightSelectedDateOnCell: cell forDate: cellDate onIndexPath: indexPath];
	if([self.delegate respondsToSelector: @selector(datePickerView:willDisplayCell:withDate:atIndexPath:)]) {
		[self.delegate datePickerView: self willDisplayCell: cell withDate: [self dateFromPickerDate: cell.date] atIndexPath: indexPath];
	}
	
	return cell;
	
}

- (void) highlightSelectedDateOnCell:(DFDatePickerDayCell *)cell forDate:(NSDate *)cellDate onIndexPath:(NSIndexPath *)indexPath {
	if(self.selectedDate && cell.isEnabled) {
		DFDatePickerDate date1 = [self pickerDateFromDate: self.selectedDate];
		DFDatePickerDate date2 = [self pickerDateFromDate: cellDate];
		cell.selected = NO;
		if(date1.day == date2.day && date1.year == date2.year && date1.month == date2.month) {
			[self.collectionView selectItemAtIndexPath: indexPath animated: NO scrollPosition: UICollectionViewScrollPositionNone];
			cell.selected = YES;
		}
	}
}

//	We are cheating by piggybacking on view state to avoid recalculation
//	in -collectionView:shouldHighlightItemAtIndexPath:
//	and -collectionView:shouldSelectItemAtIndexPath:.

//	A naïve refactoring process might introduce duplicate state which is bad too.

- (BOOL) collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return ((DFDatePickerDayCell *)[collectionView cellForItemAtIndexPath:indexPath]).enabled;
}

- (BOOL) collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	return ((DFDatePickerDayCell *)[collectionView cellForItemAtIndexPath:indexPath]).enabled;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	DFDatePickerDayCell *cell = ((DFDatePickerDayCell *)[collectionView cellForItemAtIndexPath:indexPath]);
	[self willChangeValueForKey:@"selectedDate"];
	_selectedDate = cell
		? [self.calendar dateFromComponents:[self dateComponentsFromPickerDate:cell.date]]
		: nil;
	[self didChangeValueForKey:@"selectedDate"];
	if([self.delegate respondsToSelector: @selector(datePickerView:didSelectDate:)]) {
		NSDate *cellDate = [self.calendar dateFromComponents:[self dateComponentsFromPickerDate:cell.date]];
		[self.delegate datePickerView: self didSelectDate: cellDate];
	}
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	DFDatePickerDayCell *cell = ((DFDatePickerDayCell *)[collectionView cellForItemAtIndexPath:indexPath]);
	if([self.delegate respondsToSelector: @selector(datePickerView:didDeselectDate:)]) {
		NSDate *cellDate = [self.calendar dateFromComponents:[self dateComponentsFromPickerDate:cell.date]];
		[self.delegate datePickerView: self didDeselectDate: cellDate];
	}
}

- (void) displayDate: (NSDate *) date animated:(BOOL)animated{
	self.selectedDate = date;
	NSInteger diff = [self.calendar components:NSMonthCalendarUnit fromDate:[self dateFromPickerDate:self.fromDate] toDate:date options:0].month;
	
	UICollectionView *cv = self.collectionView;
	if(diff < 0 || diff >= cv.numberOfSections) {
		_fromDate = [self pickerDateFromDate:[self.calendar dateByAddingComponents: ((^{
			NSDateComponents *dateComponents = [NSDateComponents new];
			dateComponents.month = -self.monthRange;
			return dateComponents;
		})()) toDate: date options:0]];
		_fromDate.day = 1;
		_toDate = [self pickerDateFromDate:[self.calendar dateByAddingComponents: ((^{
			NSDateComponents *dateComponents = [NSDateComponents new];
			dateComponents.month = self.monthRange;
			return dateComponents;
		})()) toDate: date options:0]];
		_toDate.day = 1;
		diff = [self.calendar components:NSMonthCalendarUnit fromDate:[self dateFromPickerDate:self.fromDate] toDate:date options:0].month;
		[self shiftDatesByComponents:((^{
			NSDateComponents *dateComponents = [NSDateComponents new];
			dateComponents.month = 0;
			return dateComponents;
		})())];
		animated = NO;
	}
	
	diff = [self.calendar components:NSMonthCalendarUnit fromDate:[self dateFromPickerDate:self.fromDate] toDate:date options:0].month;
	NSDate *firstDayInMonth = [self dateForFirstDayInSection: diff];
	NSUInteger weekday = [self.calendar components:NSWeekdayCalendarUnit fromDate:firstDayInMonth].weekday;
	DFDatePickerDate targetDate = [self pickerDateFromDate: date];
	NSInteger itemIndex = ((targetDate.day-1) + (weekday - 1));
	if(itemIndex < 7) {
		itemIndex = 7;
	}
	NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem: itemIndex inSection:diff];
	[self.collectionView scrollToItemAtIndexPath:cellIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated: animated];
}

- (void) setSelectedDate:(NSDate *)selectedDate {
	_selectedDate = selectedDate;
	[self.collectionView reloadData];
}

- (UICollectionReusableView *) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {

	if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
		
		DFDatePickerMonthHeader *monthHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:DFDatePickerViewMonthHeaderIdentifier forIndexPath:indexPath];
		
		monthHeader.backgroundColor = [UIColor whiteColor];
		NSDateFormatter *dateFormatter = [self.calendar df_dateFormatterNamed:@"calendarMonthHeader" withConstructor:^{
			NSDateFormatter *dateFormatter = [NSDateFormatter new];
			dateFormatter.calendar = self.calendar;
			dateFormatter.dateFormat = [dateFormatter.class dateFormatFromTemplate:@"yyyyLLLL" options:0 locale:[NSLocale currentLocale]];
			return dateFormatter;
		}];
		
		NSDate *formattedDate = [self dateForFirstDayInSection:indexPath.section];
		monthHeader.textLabel.text = [dateFormatter stringFromDate:formattedDate];
		
		NSArray *weekSymobls = [dateFormatter shortWeekdaySymbols];
		NSUInteger i = 0;
		for(UILabel *label in monthHeader.weekViews) {
			label.text = [weekSymobls[i++] uppercaseString];
		}
		
		return monthHeader;
		
	}
	
	return nil;

}

- (NSDate *) dateFromPickerDate:(DFDatePickerDate)dateStruct {
	return [self.calendar dateFromComponents:[self dateComponentsFromPickerDate:dateStruct]];
}

- (NSDateComponents *) dateComponentsFromPickerDate:(DFDatePickerDate)dateStruct {
	NSDateComponents *components = [NSDateComponents new];
	components.year = dateStruct.year;
	components.month = dateStruct.month;
	components.day = dateStruct.day;
	return components;
}

- (DFDatePickerDate) pickerDateFromDate:(NSDate *)date {
	NSDateComponents *components = [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
	return (DFDatePickerDate) {
		components.year,
		components.month,
		components.day
	};
}

- (void) reloadData {
	[self.collectionView reloadData];
}

- (NSArray *) visibleDates {
	NSMutableArray *array = [NSMutableArray array];
	for(DFDatePickerDayCell *cell in [self.collectionView visibleCells]) {
		if(cell.enabled) {
			CGFloat y = CGRectGetMaxY([self.collectionView convertRect: cell.frame toView: self]);
			BOOL belowHeader = (y > 64);
			if(belowHeader) {
				[array addObject: [self dateFromPickerDate: cell.date]];
			}
		}
	}
	return array;
}

- (void) setSelectable:(BOOL)selectable {
	self.collectionView.allowsSelection = selectable;
}

#pragma mark - scrollview delegate

- (void) scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
	
	if(velocity.x == velocity.y && velocity.y == 0)
		return;
	UICollectionView *cv = self.collectionView;
	UICollectionViewFlowLayout *cvLayout = self.collectionViewLayout;

	CGPoint p = cv.contentOffset;
	p.y += floorf(velocity.y*491); // magic number
	
	// find out expected stopping section offset
	CGFloat targetSection = 0;
	CGFloat sectionRows = floorf([cv numberOfItemsInSection: targetSection]/7.0f);
	CGFloat sectionFullHeight = (cvLayout.itemSize.height+cvLayout.minimumLineSpacing)*sectionRows+cvLayout.headerReferenceSize.height+cvLayout.sectionInset.top;
	CGFloat previousSectionYOffset = 0;
	while(p.y > sectionFullHeight) {
		targetSection++;
		if(targetSection >= cv.numberOfSections) {
			targetSection = cv.numberOfSections - 1;
			break;
		}
		sectionRows = floorf([cv numberOfItemsInSection: targetSection]/7.0f);
		previousSectionYOffset = sectionFullHeight;
		sectionFullHeight += (cvLayout.itemSize.height+cvLayout.minimumLineSpacing)*sectionRows+cvLayout.headerReferenceSize.height+cvLayout.sectionInset.top;
	}
	
	// find expected stopping row in section
	CGFloat itemHeight = (cvLayout.itemSize.height+cvLayout.minimumLineSpacing);
	CGFloat expectedSectionYOffset = previousSectionYOffset;
	CGFloat diff = p.y - expectedSectionYOffset;
	CGFloat subSection = floorf(diff/itemHeight);
	sectionRows = floorf([cv numberOfItemsInSection: targetSection]/7.0f);

	// skip to next month if offset will stop beyong last two rows of the section
	if(subSection > (sectionRows-2)) {
		subSection = 0;
		targetSection += 1;
		if(targetSection >= self.monthRange*2) {
			return;
		}
		sectionRows = floorf([cv numberOfItemsInSection: targetSection]/7.0f);
		expectedSectionYOffset = expectedSectionYOffset + (cvLayout.itemSize.height+cvLayout.minimumLineSpacing)*sectionRows+cvLayout.headerReferenceSize.height+cvLayout.sectionInset.top;
	}
	(*targetContentOffset).y = expectedSectionYOffset + itemHeight*subSection;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if([self.delegate respondsToSelector: @selector(datePickerViewDidEndDragging:willDecelerate:)]) {
		[self.delegate datePickerViewDidEndDragging: self willDecelerate: decelerate];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	if([self.delegate respondsToSelector: @selector(datePickerViewDidEndDecelerating:)]) {
		[self.delegate datePickerViewDidEndDecelerating: self];
	}
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	if(self.selectedDate && [self.delegate respondsToSelector: @selector(didDisplayDate:)]) {
		[self.delegate didDisplayDate: self.selectedDate];
	}
}

@end
