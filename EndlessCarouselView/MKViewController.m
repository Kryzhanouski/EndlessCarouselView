//
//  MKViewController.m
//  EndlessCarouselView
//
//  Created by Mark on 5/6/14.
//  Copyright (c) 2014 Mark Kryzhanouski. All rights reserved.
//

#import "MKViewController.h"
#import "EndlessCarouselView.h"

@interface MKViewController ()
@property (weak, nonatomic) IBOutlet EndlessCarouselView *carouselView;

@end

@implementation MKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.carouselView.items = @[@"Monday",@"Tuesday",@"Wednesday",@"Thursday",@"Friday",@"Saturday",@"Sunday"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
