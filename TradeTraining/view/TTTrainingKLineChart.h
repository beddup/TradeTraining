//
//  TTTrainingKLineChart.h
//  TradeTraining
//
//  Created by Amay on 3/31/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTKLineChart.h"
@protocol TTTrainingKLineChartDelegate <NSObject>

-(void)trainingFinished;

@end


@class TTKLineRecord;
@interface TTTrainingKLineChart : TTKLineChart

@property(weak, nonatomic) id<TTTrainingKLineChartDelegate> trainingDelegate;


-(void)trainWithRecords:(NSArray* )records;
-(void)showNextRecord;
-(TTKLineRecord* )currentTrainedRecord;

@end
