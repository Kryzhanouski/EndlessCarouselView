//
//  EndlessCarouselView.m
//  EndlessCarouselView
//
//  Created by Mark on 5/6/14.
//  Copyright (c) 2014 Mark Kryzhanouski. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "EndlessCarouselView.h"
#import "EndlessCarouselViewCell.h"


#define UIColorFromHexRGB(rgbValue, a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:a]
#define CGColorFromHexRGB(rgbValue, a) [UIColorFromHexRGB(rgbValue, a) CGColor]


@interface HeaderInfinitePickerView : UILabel {
}
- (CAGradientLayer *)layerAsCAGradientLayer;
@end


@interface EndlessCarouselView() {
    UIEdgeInsets                            _padding;
    CGFloat                                 _titleHeight;
    CGFloat                                 _cellWidth;
    
	__weak HeaderInfinitePickerView*        _lblTitle;
	UIScrollView*                           _svContent;
    
	UIImageView*                            _ivCursor;
    CGPoint                                 _cursorCenter;
	
	NSMutableArray*                         _views;
	NSInteger                               _indexToUpdate;
    NSInteger                               _lastSelectedIndex;
    
	EndlessCarouselViewCell*                 _selectedView;
	EndlessCarouselViewCell*                 _firstView;
	EndlessCarouselViewCell*                 _lastView;
	
	CGFloat                                 _previousXOffset;
    
    struct {
        unsigned int currentOrientationLandscape    :1;
        unsigned int infinite                       :1;
        unsigned int loaded                         :1;
        unsigned int needRecalculateFrames          :1;
        unsigned int needUpdateCurrentIndex         :1;
    } _infinitePickerViewFlags;
}

@property (nonatomic, retain) UIFont* itemFont;

- (void)_centerView:(UIView*)view animated:(BOOL)animating;
- (void)_createViews;
- (BOOL)_doesViewNeedCentering:(UIView *)view;
- (void)_finishPosition;
- (void)_recalculatePositions;
- (void)_selectedViewChangedToView:(EndlessCarouselViewCell *)hitingView;
@end


@implementation EndlessCarouselView

@synthesize delegate = _delegate;

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor clearColor];
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self setUpInfinitePickerView];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setUpInfinitePickerView];
}

- (void)setUpInfinitePickerView
{
    _padding = UIEdgeInsetsZero;
    _titleHeight = 0.;
    _cellWidth = 90.;
    _ivCursor = nil;
    _lastSelectedIndex = NSNotFound;
    _indexToUpdate = 0;
    _infinitePickerViewFlags.infinite = 1;
    _infinitePickerViewFlags.needRecalculateFrames = 1;
    _infinitePickerViewFlags.needUpdateCurrentIndex = 1;
    _infinitePickerViewFlags.currentOrientationLandscape = UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ? 1 : 0;
    
    _items = [NSArray new];
    _views = [NSMutableArray new];
    
    CGRect r = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(_titleHeight, 0, 0, 0));
    _svContent = [[UIScrollView alloc] initWithFrame:UIEdgeInsetsInsetRect(r, _padding)];
    _svContent.decelerationRate = UIScrollViewDecelerationRateFast;
    _svContent.backgroundColor = [UIColor clearColor];
    _svContent.showsVerticalScrollIndicator = NO;
    _svContent.showsHorizontalScrollIndicator = NO;
    _svContent.delegate = self;
    [self addSubview:_svContent];
    _cursorCenter = CGPointMake(CGRectGetMidX(_svContent.frame), CGRectGetMidY(_svContent.frame));
    
    HeaderInfinitePickerView* lblTitle = [[HeaderInfinitePickerView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), _titleHeight)];
    lblTitle.textAlignment = NSTextAlignmentCenter;
    lblTitle.font = self.itemFont;
    lblTitle.textColor = UIColorFromHexRGB(0x7C7D7C,1);
    [lblTitle layerAsCAGradientLayer].colors = [NSArray arrayWithObjects:
                                                (id)CGColorFromHexRGB(0x7e7e7e, 1),
                                                (id)CGColorFromHexRGB(0x5d5d5c, 1),
                                                nil];
    [self addSubview:lblTitle];
    _lblTitle = lblTitle;
    
    CAGradientLayer *l = [self whiteGradient];
    l.frame = self.bounds;
    self.layer.mask = l;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tap];
}

- (void)dealloc
{
    _svContent.delegate = nil;
	_items = nil;
	_views = nil;
	_ivCursor = nil;
}

- (EndlessCarouselViewCell*)selectedCell
{
    return _selectedView;
}

- (CAGradientLayer*) whiteGradient
{
    UIColor *colorOne = [UIColor colorWithWhite:1.0 alpha:0.0];
    UIColor *colorTwo = [UIColor colorWithWhite:1.0 alpha:1.0];
    UIColor *colorThree     = [UIColor colorWithWhite:1.0 alpha:1.0];
    UIColor *colorFour = [UIColor colorWithWhite:1.0 alpha:0.0];
    NSArray *colors =  [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, colorThree.CGColor, colorFour.CGColor, nil];
    
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0];
    NSNumber *stopTwo = [NSNumber numberWithFloat:0.2];
    NSNumber *stopThree = [NSNumber numberWithFloat:0.8];
    NSNumber *stopFour = [NSNumber numberWithFloat:1.0];
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, stopThree, stopFour, nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.locations = locations;
    headerLayer.startPoint = CGPointMake(0, 0.5);
    headerLayer.endPoint = CGPointMake(1., 0.5);
    return headerLayer;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
	unsigned int isLandscape = UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ? 1 : 0;
	if (isLandscape != _infinitePickerViewFlags.currentOrientationLandscape) {
		_infinitePickerViewFlags.currentOrientationLandscape = isLandscape;
		_infinitePickerViewFlags.needRecalculateFrames = 1;
		_infinitePickerViewFlags.needUpdateCurrentIndex = 1;
        _indexToUpdate = _selectedView != nil ? _selectedView.index : _indexToUpdate;
        _selectedView = nil;
        _lastSelectedIndex = NSNotFound;
	}
    
	if (_infinitePickerViewFlags.needRecalculateFrames == 1) {
		[self _recalculatePositions];
	}
}


#pragma mark - ScrollViewDelegate
// called when scroll view grinds to a halt
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self _doesViewNeedCentering:_selectedView]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_finishPosition) object:nil];
        [self performSelector:@selector(_finishPosition) withObject:nil afterDelay:0.1];
    } else {
        [self scrollViewDidEndScrollingAnimation:scrollView];
    }
}

// called on finger up if user dragged. decelerate is true if it will continue moving afterwards
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) {
        if ([self _doesViewNeedCentering:_selectedView]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_finishPosition) object:nil];
            [self performSelector:@selector(_finishPosition) withObject:nil afterDelay:0.1];
        } else {
            [self scrollViewDidEndScrollingAnimation:scrollView];
        }
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (_lastSelectedIndex != _selectedView.index) {
        _lastSelectedIndex = _selectedView.index;
        if ([self.delegate respondsToSelector:@selector(infinitePickerView:didChangeCurrentValue:)]) {
            [self.delegate infinitePickerView:self didChangeCurrentValue:[self currentValue]];
        }
        if ([self.delegate respondsToSelector:@selector(infinitePickerView:didSelectTitleAtIndex:)]) {
            [self.delegate infinitePickerView:self didSelectTitleAtIndex:_lastSelectedIndex];
        }
    }
}

// any offset changes
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (_infinitePickerViewFlags.loaded == 1) {
        if (_infinitePickerViewFlags.infinite == 1) {
            // determine direction
            CGFloat oldXOffset = _previousXOffset;
            BOOL directionToRight = (_previousXOffset - _svContent.contentOffset.x) > 0 ? NO: YES;
            _previousXOffset = _svContent.contentOffset.x;
            
            CGPoint centerPoint = CGPointMake(_cursorCenter.x, CGRectGetMidY(_svContent.frame));
            EndlessCarouselViewCell* hitingView = nil;
            BOOL containsPoint;
            EndlessCarouselViewCell* view = _selectedView;
            do {
                CGRect r = [_svContent convertRect:view.frame toView:self];
                containsPoint = CGRectContainsPoint(r, centerPoint);
                if (containsPoint) {
                    hitingView = view;
                } else {
                    view = directionToRight ? view.nextView : view.previousView;
                }
                
                if (view == _selectedView || view == nil) {
                    break;
                }
            } while (!containsPoint);
            
            if(!containsPoint) {
                _svContent.contentOffset = CGPointMake(oldXOffset, 0);
            } else if (_selectedView != hitingView && hitingView != nil) {
                [self _selectedViewChangedToView:hitingView];
            }
            
        } else {
            // determine direction
            BOOL directionToRight = (_previousXOffset - _svContent.contentOffset.x) > 0 ? NO: YES;
            _previousXOffset = _svContent.contentOffset.x;
            
            CGPoint centerPoint = CGPointMake(_cursorCenter.x, CGRectGetMidY(_svContent.frame));
            EndlessCarouselViewCell* hitingView = nil;
            BOOL containsPoint;
            EndlessCarouselViewCell* view = _selectedView;
            do {
                CGRect r = [_svContent convertRect:view.frame toView:self];
                containsPoint = CGRectContainsPoint(r, centerPoint);
                if (containsPoint) {
                    hitingView = view;
                } else {
                    view = directionToRight ? view.nextView : view.previousView;
                }
                
                if (view == _selectedView || view == nil) {
                    break;
                }
            } while (!containsPoint);
            
            if (containsPoint && _selectedView != hitingView && hitingView != nil) {
                [self _selectedViewChangedToView:hitingView];
            }
        }
	}
}


#pragma mark - Private Interface

- (BOOL)_doesViewNeedCentering:(UIView *)view
{
	CGFloat selfXCenter = _cursorCenter.x;
	CGFloat curViewXCenter = roundf([self convertPoint:view.center fromView:_svContent].x);
	CGFloat xCorrection = curViewXCenter - selfXCenter;
    return ABS(xCorrection) > 2.0f;
}

- (void)_centerView:(UIView*)view animated:(BOOL)animating
{
    CGFloat selfXCenter = _cursorCenter.x;
    CGFloat curViewXCenter = roundf([self convertPoint:view.center fromView:_svContent].x);
    CGFloat xCorrection = curViewXCenter - selfXCenter;
    if (xCorrection != 0.) {
        [_svContent setContentOffset: CGPointMake(_svContent.contentOffset.x + xCorrection,0) animated:animating];
    }
}

- (void)_finishPosition
{
	[self _centerView:_selectedView animated:YES];
}

- (void)_selectedViewChangedToView:(EndlessCarouselViewCell *)hitingView
{
	_selectedView.selected = NO;
	hitingView.selected = YES;
    
	NSInteger offset = (_selectedView.center.x - hitingView.center.x)/_cellWidth;
	BOOL isRightDirection = offset < 0;
	
	_selectedView = hitingView;
	
    if (_infinitePickerViewFlags.infinite == 1) {
        EndlessCarouselViewCell *newLastView;
        EndlessCarouselViewCell *newFirstView;
        for (int i = 0; i < abs((int)offset); i++) {
            if (isRightDirection) {
                newFirstView = _lastView;
                newLastView = _lastView.nextView;
                newFirstView.center = CGPointMake(_firstView.center.x + _cellWidth, newFirstView.center.y);
            }
            else {
                newLastView = _firstView;
                newFirstView = _firstView.previousView;
                newLastView.center = CGPointMake(_lastView.center.x - _cellWidth, newLastView.center.y);
            }
            _lastView = newLastView;
            _firstView = newFirstView;
        }
    }
}

- (void)_recalculatePositions
{
	CGRect rect = self.bounds;
    
    // layout title
	CGRect r = CGRectMake(0, 0, rect.size.width, _titleHeight);
	if (!CGRectEqualToRect(_lblTitle.frame, r)) {
		_lblTitle.frame = r;
	}
    
    // layout scroll view
    r = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(_titleHeight, 0, 0, 0));
    r = UIEdgeInsetsInsetRect(r, _padding);
	if (!CGRectEqualToRect(_svContent.frame, r)) {
		_svContent.frame = r;
	}
    
    // layout pointer
    if (_ivCursor != nil) {
        _cursorCenter = CGPointMake(CGRectGetMidX(self.bounds), _cursorCenter.y);
        _ivCursor.center = _cursorCenter;
    }
	_infinitePickerViewFlags.needRecalculateFrames = 0;
	
	if ([_views count] == 0) {
		return;
	}
    
    _selectedView = [_views objectAtIndex:0];
    _selectedView.selected = YES;
    
    if (_infinitePickerViewFlags.infinite == 1) {
        CGFloat maxContentWidth = 10000000;
        _svContent.contentSize = CGSizeMake(maxContentWidth, CGRectGetHeight(_svContent.frame));
        _svContent.contentOffset = CGPointMake(roundf(maxContentWidth/2), 0);
        
        NSUInteger middleIndex = [_views count]/2;
        NSMutableArray *tempArr = [NSMutableArray array];
        for (NSUInteger i = middleIndex; i < [_views count]; i++) {
            [tempArr addObject:[_views objectAtIndex:i]];
        }
        for (int i = 0; i < middleIndex; i++) {
            [tempArr addObject:[_views objectAtIndex:i]];
        }
        
        _lastView = [tempArr objectAtIndex:0];
        _firstView = [tempArr lastObject];
        
        if ([_views count] % 2 != 0) {
            middleIndex++;
        }
        
        _previousXOffset = _svContent.contentOffset.x;
        CGFloat heightBlock = CGRectGetHeight(_svContent.frame);
        CGFloat x = maxContentWidth/2 - _cellWidth/2 + CGRectGetWidth(_svContent.frame)/2 - _cellWidth*middleIndex;
        x = roundf(x);
        for (EndlessCarouselViewCell* cell in tempArr) {
            r = CGRectMake(x, 0, _cellWidth, heightBlock);
            r = CGRectIntegral(r);
            cell.frame = r;
            x += CGRectGetWidth(cell.frame);
        }
        
    } else {
        _firstView = [_views objectAtIndex:0];
        _lastView = [_views lastObject];
        
        CGFloat cellPaddingX[2] = {25., 25.}; //{left, right}
        
        CGFloat contentPaddingXLeft = (CGRectGetWidth(_svContent.frame)-([_firstView.text sizeWithAttributes:@{NSFontAttributeName:_firstView.font}].width+cellPaddingX[0]+cellPaddingX[1]))/2;
        contentPaddingXLeft = floorf(contentPaddingXLeft);
        CGFloat contentPaddingXRight = (CGRectGetWidth(_svContent.frame)-([_lastView.text sizeWithAttributes:@{NSFontAttributeName:_lastView.font}].width+cellPaddingX[0]+cellPaddingX[1]))/2;
        contentPaddingXRight = floorf(contentPaddingXRight);
        
        CGFloat heightBlock = CGRectGetHeight(_svContent.frame);
        CGFloat contentWidth = contentPaddingXLeft;
        for (EndlessCarouselViewCell* cell in _views) {
            CGFloat w = [cell.text sizeWithAttributes:@{NSFontAttributeName:cell.font}].width+cellPaddingX[0]+cellPaddingX[1];
            r = CGRectMake(contentWidth, 0, w, heightBlock);
            r = CGRectIntegral(r);
            cell.frame = r;
            contentWidth += CGRectGetWidth(cell.frame);
        }
        
        CGSize size = CGSizeMake(contentWidth+contentPaddingXRight, CGRectGetHeight(_svContent.frame));
        _svContent.contentSize = size;
        _svContent.contentOffset = CGPointZero;
        _previousXOffset = _svContent.contentOffset.x;
    }
    [self setNeedsDisplay];
    
    _infinitePickerViewFlags.loaded = 1;
    
    if (_infinitePickerViewFlags.needUpdateCurrentIndex == 1) {
        [self setCurrentIndex:_indexToUpdate animated:NO];
    } else {
        [self performSelector:@selector(_firstCenteringCurrentView) withObject:nil afterDelay:0.01f];
    }
}

- (void)_firstCenteringCurrentView
{
	[self _centerView:_selectedView animated:NO];
}

- (void)_createViews
{
	NSUInteger cnt = [_items count];
    if (cnt > 0) {
        BOOL isInfinite = _infinitePickerViewFlags.infinite == 1;
        NSUInteger minCountOfViews = 10;
        NSInteger  countOfSets = minCountOfViews/cnt + 1;
        if (!isInfinite) {
            countOfSets = 1;
        }
        
        EndlessCarouselViewCell *theFirstView = nil;
        EndlessCarouselViewCell *previousView = nil;
        for (NSInteger set = 0; set < countOfSets; set++) {
            for (int index = 0; index < cnt; index++) {
                EndlessCarouselViewCell *aCell = [EndlessCarouselViewCell new];
                aCell.userInteractionEnabled = NO;
                id item = [_items objectAtIndex:index];
                if ([item isKindOfClass:[UIView class]]) {
                    // make a copy
                    NSData* itemData = [NSKeyedArchiver archivedDataWithRootObject:item];
                    UIView* copy = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
                    aCell.contentView = copy;
                }
                else {
                    aCell.text = item;
                }
                UIFont* font = self.itemFont;
                if (font == nil) {
                    font = [UIFont systemFontOfSize:16];
                }
                aCell.font = font;
                aCell.index = index;
                [_svContent addSubview:aCell];
                [_views addObject:aCell];
                
                //for the first view
                if (set == 0 && index == 0) {
                    theFirstView = aCell;
                }
                
                previousView.nextView = aCell;
                aCell.previousView = previousView;
                
                previousView = aCell;
                
                //for the last view
                if (isInfinite && set == countOfSets-1 && index == cnt-1) {
                    aCell.nextView = theFirstView;
                    theFirstView.previousView = aCell;
                }
            }
        }
    }
}


#pragma mark - Public Interface
- (NSUInteger)currentIndex
{
	return _selectedView.index;
}

- (id)currentValue
{
    NSUInteger index = _selectedView.index;
    if (_selectedView == nil || [_items count] <= index) {
        return nil;
    }
	return [_items objectAtIndex:index];
}

- (BOOL)infinite
{
    return _infinitePickerViewFlags.infinite == 1;
}

- (NSArray *)items
{
	return [NSArray arrayWithArray:_items];
}

- (void)setBackgroundImage:(UIImage *)image
{
    self.layer.contents = (id)image.CGImage;
}

- (void)setCurrentIndex:(NSUInteger)newIndex animated:(BOOL)animated
{
	if (_infinitePickerViewFlags.loaded == 0) {
		_infinitePickerViewFlags.needUpdateCurrentIndex = 1;
		_indexToUpdate = newIndex;
        _lastSelectedIndex = NSNotFound;
		return;
	}
	
	if (newIndex == _selectedView.index) {
		return;
    }
	
	EndlessCarouselViewCell* foundView = _selectedView;
	BOOL isRightDirection = newIndex > _selectedView.index;
	
	for (int i = 0; i < abs((int)(newIndex - _selectedView.index)); i++) {
		foundView = isRightDirection ? foundView.nextView : foundView.previousView;
	}
	
	if (foundView.index == newIndex) {
		[self _centerView:foundView animated:animated];
	}
	
	_infinitePickerViewFlags.needUpdateCurrentIndex = 0;
    _lastSelectedIndex = _indexToUpdate;
	_indexToUpdate = NSNotFound;
}

- (void)setCurrentItem:(id)value animated:(BOOL)animated
{
    NSInteger index = [_items indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        *stop = [obj isEqual:value];
        return *stop;
    }];
    [self setCurrentIndex:index animated:animated];
}

- (void)setInfinite:(BOOL)infinite
{
    BOOL current = _infinitePickerViewFlags.infinite == 1;
    if (current != infinite) {
        _infinitePickerViewFlags.infinite = infinite ? 1 : 0;
        
        _infinitePickerViewFlags.loaded = 0;
        _indexToUpdate = _selectedView.index;
        _selectedView = nil;
        _lastView = nil;
        _firstView = nil;
        
        [_views makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_views removeAllObjects];
        if ([_items count] > 0) {
            [self _createViews];
        }
        
        _infinitePickerViewFlags.needRecalculateFrames = 1;
        _infinitePickerViewFlags.needUpdateCurrentIndex = 1;
        [self setNeedsLayout];
    }
}

- (void)setItems:(NSArray *)newItems
{
	_infinitePickerViewFlags.loaded = 0;
	_selectedView = nil;
	_lastView = nil;
	_firstView = nil;
	
	_items = newItems;
    
	for (UIView *view in _views) {
		[view removeFromSuperview];
	}
	[_views removeAllObjects];
	[self _createViews];
    
    _infinitePickerViewFlags.needRecalculateFrames = 1;
    [self setNeedsLayout];
}

- (void)setNext
{
	[self _centerView:_selectedView.nextView animated:YES];
}

- (void)setPaddings:(UIEdgeInsets)paddings
{
    _padding = paddings;
    _infinitePickerViewFlags.needRecalculateFrames = 1;
    [self setNeedsLayout];
}

- (void)setPointer:(UIImage *)pointer
{
    if (_ivCursor == nil) {
        _ivCursor = [[UIImageView alloc] initWithImage:pointer];
        _ivCursor.backgroundColor = [UIColor clearColor];
        [self addSubview:_ivCursor];
    } else {
        _ivCursor.image = pointer;
        [_ivCursor sizeToFit];
    }
    [self setNeedsLayout];
}

- (void)setPointerCenter:(CGPoint)center
{
    _cursorCenter = center;
    [self setNeedsLayout];
}

- (void)setTitle:(NSString *)newTitle
{
	_lblTitle.text = [NSString stringWithString:newTitle];
}

- (void)setPrevious
{
	[self _centerView:_selectedView.previousView animated:YES];
}


#pragma mark - UIGestureRecognizer handlers
- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        // find an index
        NSInteger index = [_views indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            EndlessCarouselView* cell = (EndlessCarouselView *)obj;
            *stop = [cell pointInside:[recognizer locationInView:cell] withEvent:nil];
            return *stop;
        }];
        // get a view
        //TODO: here is an issue when a user starts tapping before the first view or after the last view and no one of these views is selected yet.
        //      index becomes NSNotFound and the picker starts centering the selected view until one of views above will not fall under a finger. Repeat.
        EndlessCarouselViewCell* view = (index != NSNotFound ? [_views objectAtIndex:index] : _selectedView);
        if ([self _doesViewNeedCentering:view]) {
            [self _centerView:view animated:YES];
        } else if ([self.delegate respondsToSelector:@selector(infinitePickerView:didPressValue:)] && index != NSNotFound) {
            [self.delegate infinitePickerView:self didPressValue:[_items objectAtIndex:index]];
        }
    }
}

@end



@implementation HeaderInfinitePickerView

+ (Class)layerClass {
	return [CAGradientLayer class];
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (CAGradientLayer *)layerAsCAGradientLayer {
	return (CAGradientLayer *)self.layer;
}

@end
