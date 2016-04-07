//
//  TTKLineRecordsManager.m
//  TradeTraining
//
//  Created by Amay on 3/20/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTKLineRecordsManager.h"
#import "TTStockMarketDataProvider.h"
#import "NSDate+Extension.h"

@interface TTKLineRecordsManager()

@property(strong, nonatomic) NSMutableDictionary* records; // klineType: records

@property(strong, nonatomic) TTStockMarketDataProvider* recordsProvider;

@property(strong, nonatomic) NSMutableDictionary* earlistDates;


@end


@implementation TTKLineRecordsManager

-(NSString*) kLineType{
    if (!_kLineType) {
        _kLineType = TTKlineTypeDay;
    }
    return _kLineType;
}

-(TTStockMarketDataProvider*) recordsProvider{
    if (!_recordsProvider) {
        _recordsProvider= [[TTStockMarketDataProvider alloc] init];
    }
    return _recordsProvider;
}

-(NSMutableDictionary*)records{
    if (!_records) {
        _records = [@{TTKlineTypeDay:@[],TTKlineTypeMonth:@[],TTKlineTypeWeek:@[]} mutableCopy];
    }
    return _records;
}
-(void)setStockCode:(NSString *)stockCode{
    if (_stockCode != stockCode) {
        _stockCode = stockCode;
        self.records = nil;
    }

}

-(NSArray* )getLocalRecordsFrom:(NSDate* )from to:(NSDate *)to type:(NSString *)type{

    NSArray * localRecords = self.records[type];
    NSInteger startIndex = -1;
    NSInteger endIndex = -1;
    for (NSInteger index = 0 ; index < localRecords.count; index++) {
        TTKLineRecord* record = localRecords[index];
        if ([record.date timeIntervalSinceDate:from] >= 0  ) {
            endIndex = index;
        }
        if (startIndex == -1 && [record.date timeIntervalSinceDate:to] <= 0 ) {
            startIndex = index;
        }
    }

    if (startIndex >= 0 && endIndex >= 0) {
        return [localRecords subarrayWithRange:NSMakeRange(startIndex, endIndex-startIndex)];
    }
    return @[];

}

-(void)getRecordsFrom:(NSDate *)fromDate
                   to:(NSDate *)toDate
    completionHandler:(void (^)(NSArray *,NSString*))completionHander{

    // check the existing records
    NSDate* earlistDate = self.earlistDates[self.kLineType];
    if ([fromDate timeIntervalSinceDate:earlistDate] >= 0 ) {
        NSArray* desiredRecords = [self getLocalRecordsFrom:fromDate to:toDate type:self.kLineType];
        completionHander(desiredRecords,self.kLineType);
    }else{
        [self.recordsProvider getHistoryData:self.stockCode
                                        From:fromDate
                                          to:[earlistDate offsetDays:-1]
                                        type:self.kLineType success:^(NSArray *kLineRecords,NSString* kType) {

                                            NSArray* allRecords = [self.records[self.kLineType] arrayByAddingObjectsFromArray:kLineRecords];

                                            for (NSInteger index = allRecords.count - 1; index >= 0; index--) {
                                                TTKLineRecord* record = allRecords[index];
                                                if (index+5 < allRecords.count) {
                                                    record.MA5 = [[[allRecords subarrayWithRange:NSMakeRange(index+1, 5)] valueForKeyPath:@"@avg.closePrice"] floatValue];
                                                }
                                                if (index+10 < allRecords.count) {
                                                    record.MA10 =[[[allRecords subarrayWithRange:NSMakeRange(index+1, 10)] valueForKeyPath:@"@avg.closePrice"] floatValue];
                                                }
                                                if (index+20 < allRecords.count) {
                                                    record.MA20 =[[[allRecords subarrayWithRange:NSMakeRange(index+1, 20)] valueForKeyPath:@"@avg.closePrice"] floatValue];
                                                }

                                            }
                                            self.records[self.kLineType] = allRecords;
                                            self.earlistDates[self.kLineType] = fromDate;
                                            NSArray* desiredRecords = [self getLocalRecordsFrom:fromDate to:toDate type:self.kLineType];
                                            completionHander(desiredRecords,kType);

        } failure:nil];

    }
}

-(instancetype)init{
    self = [super init];
    if (self) {
        NSDate* date = [NSDate distantFuture];
        _earlistDates = [@{TTKlineTypeDay:date,TTKlineTypeMonth:date,TTKlineTypeWeek:date} mutableCopy];
    }
    return self;
}
@end
