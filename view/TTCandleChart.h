//
//  TTKLineChart.h
//  TradeTraining
//
//  Created by Amay on 3/21/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTKLineRecord.h"
@protocol TTCandleChartDelegate

-(void)focusedRecord:(TTKLineRecord*)focusedRecord inRightHalfArea:(BOOL)rightHalf;
-(void)pricenRangeChangedWithMaxPrice:(float)max minPrice:(float)min;
-(void)feedMoreDateCompletionHandler:(void(^)()) completionHandler;

@end


@interface TTCandleChart : UIView

@property(strong, nonatomic) NSString* kLineType;

@property(strong, nonatomic) NSArray* records; // the last object is the earlist k line data

@property(nonatomic) BOOL showDate; //

@property(weak,nonatomic)id <TTCandleChartDelegate> delegate;

@end
