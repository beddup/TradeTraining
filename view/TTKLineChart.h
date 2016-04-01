//
//  TTKLineChart.h
//  TradeTraining
//
//  Created by Amay on 3/21/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTKLineRecord.h"

@protocol TTKLineChartDataSource

-(void)getRecordsOfStock:(NSString* )stockCode
                    From:(NSDate*)from
                      to:(NSDate*)to
               kLineType:(NSString*)kLineType
        completionHander:(void(^)(NSArray* records)) completionHander;

@end


@interface TTKLineChart : UIView

@property(strong, nonatomic) NSString* stockCode;
@property(strong, nonatomic) NSString* kLineType;

@property(strong, nonatomic) NSArray* records; // the last object is the earlist k line data
@property(nonatomic) BOOL showDate; //

@property(weak, nonatomic)id<TTKLineChartDataSource>dataSource;

@end
