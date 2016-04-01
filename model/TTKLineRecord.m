//
//  TTSingleCandle.m
//  TradeTraining
//
//  Created by Amay on 3/18/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTKLineRecord.h"
//#import "NSDate+Extension.h"

NSString* const TTKlineTypeDay = @"d";
NSString* const TTKlineTypeWeek = @"w";
NSString* const TTKlineTypeMonth = @"m";

@interface TTKLineRecord()

@property(strong, nonatomic) NSDateFormatter* yahooichartDateFormatter;

@end

@implementation TTKLineRecord

-(NSDateFormatter *)yahooichartDateFormatter{
    if (!_yahooichartDateFormatter) {
        _yahooichartDateFormatter = [[NSDateFormatter alloc] init];
        _yahooichartDateFormatter.calendar = [NSCalendar currentCalendar];
        _yahooichartDateFormatter.dateFormat = @"yyyy-MM-dd";
    }
    return _yahooichartDateFormatter;

}

-(instancetype)initWithOpen:(float)openPrice close:(float)closePrice max:(float)maxPrice min:(float)minPrice volumn:(NSInteger)volumn date:(NSDate *)date previousClosePrice:(float)previousClosePrice{
    self = [super init];

    // check parameter
    if (openPrice < 0 || closePrice < 0 || maxPrice < 0 || minPrice < 0 || volumn < 0 || maxPrice < minPrice || date == nil) {
        return  nil;
    }

    if (self) {
        _openPrice = openPrice;
        _closePrice = closePrice;
        _maxPrice = maxPrice;
        _minPrice = minPrice;
        _volumn = volumn;
        _date = date;
        _previousClosePrice = previousClosePrice;

        _MA5 = 0;
        _MA10 = 0;
        _MA20 = 0;
    }
    return self;
}
-(instancetype)initWithYahooichartString:(NSString *)string previousString:(NSString* )previousString stockCode:(NSString*)code{


    NSArray* record = [string componentsSeparatedByString:@","];//Date,Open,High,Low,Close,Volume,Adj Close
    NSArray* previousRecord = [previousString componentsSeparatedByString:@","];
    if (record.count < 7 || (((NSString *)record[5]).integerValue == 0 && ![code isEqualToString:@"000001.ss"] && ![code isEqualToString:@"399001.sz"])) {
        return nil;
    }
    if (previousRecord.count < 7 || (((NSString *)previousRecord[5]).integerValue == 0 && ![code isEqualToString:@"000001.ss"] && ![code isEqualToString:@"399001.sz"])) {
        return nil;
    }

    return [[TTKLineRecord alloc] initWithOpen:((NSString *)record[1]).floatValue
                                         close:((NSString *)record[4]).floatValue
                                           max:((NSString *)record[2]).floatValue
                                           min:((NSString *)record[3]).floatValue
                                        volumn:((NSString *)record[5]).integerValue / 1000
                                          date:[[self.yahooichartDateFormatter dateFromString:record[0]] dateByAddingTimeInterval:60 * 60]
                            previousClosePrice:((NSString*)previousRecord[4]).floatValue];

}

@end
