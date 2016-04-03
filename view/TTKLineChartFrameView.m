//
//  TTKLineChartFrameView.m
//  TradeTraining
//
//  Created by Amay on 4/3/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTKLineChartFrameView.h"

@implementation TTKLineChartFrameView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    // draw k line area frame
    float kLineAreaHeight = CGRectGetHeight(rect) * self.KlineAreaHeightRatio;

    UIBezierPath * kLineFrame = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, CGRectGetWidth(self.bounds), kLineAreaHeight)];
    kLineFrame.lineWidth = 0.5;
    [[UIColor lightGrayColor] setStroke];
    [kLineFrame stroke];

    // draw k line reference line and price
    UIBezierPath * referenceLine = [UIBezierPath bezierPath];
    referenceLine.lineWidth = 0.5;
    CGFloat lineDash[] = {3,2}  ;
    [referenceLine setLineDash:lineDash count:1 phase:1];
    for (NSInteger index = 1; index < self.axisPriceZoneCount; index++) {
        CGFloat referenceLineY = kLineAreaHeight / self.axisPriceZoneCount * index;
        [referenceLine moveToPoint:CGPointMake(0,  referenceLineY)];
        [referenceLine addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds), referenceLineY)];
    }
    [referenceLine stroke];

    // draw volumn Frame
    UIBezierPath* volumnFrame = [UIBezierPath bezierPathWithRect:CGRectMake(0, kLineAreaHeight + self.klineAndVolumSpace, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - kLineAreaHeight - self.klineAndVolumSpace)];
    volumnFrame.lineWidth = 0.5;
    [volumnFrame stroke];

}

#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{
    self.backgroundColor = [UIColor clearColor];

}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

@end
