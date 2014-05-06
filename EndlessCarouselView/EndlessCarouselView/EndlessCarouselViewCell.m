//
//  EndlessCarouselViewCell.m
//  EndlessCarouselView
//
//  Created by Mark on 5/6/14.
//  Copyright (c) 2014 Mark Kryzhanouski. All rights reserved.
//

#import "EndlessCarouselViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation EndlessCarouselViewCell

@synthesize text = _text;
@synthesize font = _font;
@synthesize index			= _index;
@synthesize	nextView		= _nextView;
@synthesize	previousView	= _previousView;


- (void)setText:(NSString *)text
{
    _text = text;
    
    [self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    [self setNeedsDisplay];
}

- (id)init
{
	return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
	return [self initWithFrame:frame andIndex:0];
}

- (id)initWithFrame:(CGRect)frame andIndex:(NSUInteger)theIndex
{
    if ((self = [super initWithFrame:frame])) {
		_index = theIndex;
        self.backgroundColor = [UIColor clearColor];
        self.selected = NO;
    }
    return self;
}

- (void)dealloc
{
    self.nextView = nil;
    self.previousView = nil;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        [self setFont:[UIFont boldSystemFontOfSize:16]];
    } else {
        [self setFont:[UIFont systemFontOfSize:16]];
    }
}

- (void)setContentView:(UIView *)contentView
{
    [_contentView removeFromSuperview];
    _contentView = contentView;
    if (_contentView) {
        [self addSubview:_contentView];
        [_contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_contentView]|" options:0 metrics:nil views:@{@"_contentView":_contentView}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_contentView]|" options:0 metrics:nil views:@{@"_contentView":_contentView}]];
    }
}

- (void)drawRect:(CGRect)rect
{
    if (self.text == nil) {
        return;
    }
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // draw text
    CGContextSaveGState(ctx);
    if (self.selected) {
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:((float)((0xC8C7C7 & 0xFF0000) >> 16))/255.0 green:((float)((0xC8C7C7 & 0xFF00) >> 8))/255.0 blue:((float)(0xC8C7C7 & 0xFF))/255.0 alpha:1].CGColor);
    }else{
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:((float)((0x7c7d7c & 0xFF0000) >> 16))/255.0 green:((float)((0x7c7d7c & 0xFF00) >> 8))/255.0 blue:((float)(0x7c7d7c & 0xFF))/255.0 alpha:1].CGColor);
    }
    
    
    NSString* theText = self.text;
    UIFont* theFont = self.font;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    CGFloat theHeight = [theText sizeWithAttributes:@{NSFontAttributeName:theFont}].height;
#else
    CGFloat theHeight = [theText sizeWithFont:theFont].height;
#endif
    CGRect drawingRect = CGRectIntegral(CGRectMake(CGRectGetMinX(rect),
                                                   (CGRectGetHeight(rect)-theHeight) / 2,
                                                   CGRectGetWidth(rect),
                                                   theHeight));
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setLineBreakMode:NSLineBreakByTruncatingTail];
    [style setAlignment:NSTextAlignmentCenter];
    [theText drawInRect:drawingRect withAttributes:@{NSFontAttributeName:theFont,NSParagraphStyleAttributeName:style}];
#else
    [theText drawInRect:drawingRect withFont:theFont lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentCenter];
#endif
    CGContextRestoreGState(ctx);
}

@end
