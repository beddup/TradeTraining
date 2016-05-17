//
//  TTTrainingKLineChart.m
//  TradeTraining
//
//  Created by Amay on 3/31/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTTrainingKLineChart.h"

@interface TTTrainingKLineChart()

@property(nonatomic) NSArray* trainingRecords;
@property(nonatomic) NSInteger currentTrainingRecordIndex;

@end

@implementation TTTrainingKLineChart


-(void)trainWithRecords:(NSArray *)records{

    self.showDate  = NO;
    self.trainingRecords = records;
    self.currentTrainingRecordIndex = records.count / 3;

    self.records = [records subarrayWithRange:NSMakeRange(self.currentTrainingRecordIndex, records.count - self.currentTrainingRecordIndex - 1)];
}

-(void)showNextRecord{

    self.currentTrainingRecordIndex -= 1;
    if (self.currentTrainingRecordIndex < 0 ) {
        [self.trainingDelegate trainingFinished];
    }else{
        self.records = [@[self.trainingRecords[self.currentTrainingRecordIndex]] arrayByAddingObjectsFromArray:self.records];
    }

    
}
-(TTKLineRecord *)currentTrainedRecord{
    return (TTKLineRecord *)self.records[0];
}
@end
