//
//  TTSingleCandle.h
//  TradeTraining
//
//  Created by Amay on 3/18/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const TTKlineTypeDay;
extern NSString* const TTKlineTypeWeek;
extern NSString* const TTKlineTypeMonth;


@interface TTKLineRecord : NSObject

@property(strong, nonatomic) NSDate* date; // the K line may be day / week / month

// price and volumn
@property(nonatomic) float openPrice;
@property(nonatomic) float closePrice;
@property(nonatomic) float previousClosePrice;
@property(nonatomic) float maxPrice;
@property(nonatomic) float minPrice;
@property(nonatomic) NSInteger volumn;


// MA
@property(nonatomic) float MA5;
@property(nonatomic) float MA10;
@property(nonatomic) float MA20;


-(instancetype)initWithOpen:(float)openPrice
                      close:(float)closePrice
                        max:(float)maxPrice
                        min:(float)minPrice
                     volumn:(NSInteger)volumn  // unit: 1K 
                       date:(NSDate *)date
         previousClosePrice:(float)previousClosePrice;

-(instancetype)initWithYahooichartString:(NSString *)string stockCode:(NSString*)stockCode; // @"Date,Open,High,Low,Close,Volume,Adj Close"


@end
