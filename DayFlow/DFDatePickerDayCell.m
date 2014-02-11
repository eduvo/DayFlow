#import "DFDatePickerDayCell.h"

@interface DFDatePickerDayCell ()
+ (NSCache *) imageCache;
+ (id) cacheKeyForPickerDate:(DFDatePickerDate)date selectedState:(BOOL) selected;
+ (id) fetchObjectForKey:(id)key withCreator:(id(^)(void))block;
@property (nonatomic, readonly, strong) UIImageView *imageView;
@end

@implementation DFDatePickerDayCell
@synthesize imageView = _imageView;

- (id) initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor whiteColor];
		self.layer.cornerRadius = 6.0f;
		self.clipsToBounds = YES;
		self.layer.borderWidth = 1.0f;
		self.layer.borderColor = [UIColor colorWithRed:217/255.0f green:218/255.0f blue: 220/255.0f alpha: 1].CGColor;
	}
	return self;
}

- (void) setDate:(DFDatePickerDate)date {
	_date = date;
	[self setNeedsLayout];
}

- (void) setEnabled:(BOOL)enabled {
	_enabled = enabled;
	[self setNeedsLayout];
}

- (void) setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];
	self.contentView.backgroundColor = [UIColor whiteColor];
	[self setNeedsLayout];
}
- (void) setSelected:(BOOL)selected {
	[super setSelected:selected];
	[self setNeedsLayout];
}

- (void) layoutSubviews {
	
	[super layoutSubviews];
	
	//	Instead of using labels, use images keyed by day.
	//	This avoids redrawing text within labels, which involve lots of parts of
	//	WebCore and CoreGraphics, and makes sure scrolling is always smooth.
	
	//	Reason: when the view is first shown, all common days are drawn once and cached.
	//	Memory pressure is also low.
	
	//	Note: Assumption! If there is a calendar with unique day names
	//	we will be in big trouble. If there is one odd month with 1000 days we will
	//	also be in some sort of trouble. But for most use cases we are probably good.
	
	//	We still have DFDatePickerMonthHeader take a NSDateFormatter formatted title
	//	and draw it, but since that’s only one bitmap instead of 35-odd (7 weeks)
	//	that’s mostly okay.
	
	self.imageView.alpha = self.enabled ? 1.0f : 0.25f;
	
	if(self.selected || self.highlighted) {
		self.layer.borderColor = [UIColor colorWithRed:71/255.0f green:140/255.0f blue:254/255.0f alpha:1].CGColor;
	} else {
		self.layer.borderColor = [UIColor colorWithRed:217/255.0f green:218/255.0f blue: 220/255.0f alpha: 1].CGColor;
	}
	
	self.imageView.image = [[self class] fetchObjectForKey:[[self class] cacheKeyForPickerDate:self.date selectedState: NO] withCreator:^{
		
		UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, self.window.screen.scale);
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		CGContextSetFillColorWithColor(context, [UIColor colorWithRed:256.0f/256.0f green:256.0f/256.0f blue:256.0f/256.0f alpha:1.0f].CGColor);

		CGContextFillRect(context, self.bounds);
		
		NSString *dayString = [NSString stringWithFormat:@"%i", self.date.day];
		UIFont *font = [UIFont fontWithName: @"HelveticaNeue-Thin" size: 40];
		if(!font) {
			font = [UIFont systemFontOfSize: 40];
		}
		NSDictionary *fontAttributes = @{
																		 NSFontAttributeName:font,
																		 NSForegroundColorAttributeName:[UIColor colorWithRed:80/255.0f green: 101/255.0f blue:134/255.0f alpha:1]
																		 };
		if([dayString respondsToSelector: @selector(sizeWithAttributes:)]) {
			CGSize size = [dayString sizeWithAttributes: fontAttributes];
			CGRect textBounds = (CGRect){
				(CGRectGetWidth(self.bounds)-size.width)/2,
				(CGRectGetHeight(self.bounds)-size.height)/2,
				size
			};
			[dayString drawInRect: textBounds withAttributes: fontAttributes];
		} else {
			CGSize size = [dayString sizeWithFont: font];
			CGRect textBounds = (CGRect){
				(CGRectGetWidth(self.bounds)-size.width)/2,
				(CGRectGetHeight(self.bounds)-size.height)/2,
				size
			};
			
			CGContextSetFillColorWithColor(context, [UIColor colorWithRed:80/255.0f green: 101/255.0f blue:134/255.0f alpha:1].CGColor);
			[dayString drawInRect:textBounds withFont:font lineBreakMode:NSLineBreakByCharWrapping alignment:NSTextAlignmentCenter];
		}
		
		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		return image;
		
	}];
}

- (UIImageView *) imageView {
	if (!_imageView) {
		_imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
		_imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		[self.contentView addSubview:_imageView];
	}
	return _imageView;
}

+ (NSCache *) imageCache {
	static NSCache *cache;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		cache = [NSCache new];
	});
	return cache;
}

+ (id) cacheKeyForPickerDate:(DFDatePickerDate)date selectedState:(BOOL) selected {
	return [NSString stringWithFormat: @"%@%@",[@(date.day) stringValue],(selected?@"s":@"")];
}

+ (id) fetchObjectForKey:(id)key withCreator:(id(^)(void))block {
	id answer = [[self imageCache] objectForKey:key];
	if (!answer) {
		answer = block();
		[[self imageCache] setObject:answer forKey:key];
	}
	return answer;
}

@end
