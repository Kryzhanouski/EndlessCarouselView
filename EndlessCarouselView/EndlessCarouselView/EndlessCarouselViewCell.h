//
//  EndlessCarouselViewCell.h
//  EndlessCarouselView
//
//  Created by Mark on 5/6/14.
//  Copyright (c) 2014 Mark Kryzhanouski. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EndlessCarouselViewCell : UIControl {
@private
    NSString*                       _text;
    UIFont*                         _font;
    NSUInteger                      _index;
    EndlessCarouselViewCell* __weak  _nextView;
    EndlessCarouselViewCell* __weak  _previousView;
}

@property (nonatomic, strong) NSString*               text;
@property (nonatomic, strong) UIFont*                 font;
@property (nonatomic, strong) UIView* contentView;
@property (nonatomic, assign) NSUInteger              index;
@property (nonatomic, weak)   EndlessCarouselViewCell* nextView;
@property (nonatomic, weak)   EndlessCarouselViewCell* previousView;

- (id)initWithFrame:(CGRect)frame andIndex:(NSUInteger)theIndex;

@end
