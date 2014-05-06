//
//  EndlessCarouselView.h
//  EndlessCarouselView
//
//  Created by Mark on 5/6/14.
//  Copyright (c) 2014 Mark Kryzhanouski. All rights reserved.
//

#import <UIKit/UIKit.h>


@class EndlessCarouselView;

@protocol EndlessCarouselViewDelegate <NSObject>
@optional
- (void)infinitePickerView:(EndlessCarouselView *)sender didChangeCurrentValue:(id)value;
- (void)infinitePickerView:(EndlessCarouselView *)sender didSelectTitleAtIndex:(NSUInteger)index;
- (void)infinitePickerView:(EndlessCarouselView *)sender didPressValue:(id)value;
@end


@class CALayer;
@class HeaderInfinitePickerView;
@class EndlessCarouselViewCell;

@interface EndlessCarouselView : UIView<UIScrollViewDelegate> {
@private
	NSArray*                                    _items;
	__weak id<EndlessCarouselViewDelegate>      _delegate;
}

@property (nonatomic, weak)     IBOutlet id<EndlessCarouselViewDelegate>  delegate;
@property (nonatomic, assign)   BOOL                                     infinite;
@property (nonatomic, strong, readonly) EndlessCarouselViewCell*                 selectedCell;
@property (nonatomic, strong, readonly) EndlessCarouselViewCell*                 previousCell;
@property (nonatomic, strong, readonly) EndlessCarouselViewCell*                 nextCell;


- (void)setBackgroundImage:(UIImage *)image;
- (void)setPaddings:(UIEdgeInsets)paddings;
- (void)setPointer:(UIImage *)pointer;
- (void)setPointerCenter:(CGPoint)center;
- (void)setTitle:(NSString *)newTitle;

// Array of NSStrings or UIViews
- (NSArray *)items;
- (void)setItems:(NSArray *)newItems;

- (void)setItemFont:(UIFont*)font;
- (UIFont*)itemFont;

- (id)currentValue;

- (IBAction)setNext;
- (IBAction)setPrevious;
- (void)setCurrentIndex:(NSUInteger)newIndex animated:(BOOL)animated;
- (void)setCurrentItem:(id)value animated:(BOOL)animated;
- (NSUInteger)currentIndex;

@end
