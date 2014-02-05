#import "DFDatePickerMonthHeader.h"

@interface DFDatePickerMonthHeader ()

@end

@implementation DFDatePickerMonthHeader
@synthesize textLabel = _textLabel;
@synthesize weekViews = _weekViews;

- (NSArray *) weekViews {
	if(!_weekViews) {
		NSMutableArray *array = [NSMutableArray array];
		for(NSUInteger index = 0; index < 7; index++) {
			UILabel *label = [[UILabel alloc] initWithFrame: (CGRect){10+index*90+index*5,40,90,30}];
			[array addObject: label];
			label.textAlignment = NSTextAlignmentCenter;
			label.textColor = [UIColor colorWithRed:80/255.0f green: 101/255.0f blue:134/255.0f alpha:1];
			label.font = [UIFont systemFontOfSize: 12];//[UIFont fontWithName: @"HelveticaNeue" size: 12];
			[self addSubview: label];
			_weekViews = array;
		}
	}
	return _weekViews;
}

- (UILabel *) textLabel {
	if (!_textLabel) {
		_textLabel = [[UILabel alloc] initWithFrame:self.bounds];
		_textLabel.textAlignment = NSTextAlignmentCenter;
		_textLabel.font = [UIFont systemFontOfSize:20.0f];
		_textLabel.textColor = [UIColor colorWithRed:80/255.0f green: 101/255.0f blue:134/255.0f alpha:1];
		_textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		[self addSubview:_textLabel];
	}
	return _textLabel;
}

@end
