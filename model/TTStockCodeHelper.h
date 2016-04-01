//
//  TTStockCodeHelper.h
//  TradeTraining
//
//  Created by Amay on 3/20/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StockCode;
@interface TTStockCodeHelper : NSObject

+(void)updateStockCode;

+(NSArray* )searchStock:(NSString*)keyword;

+(StockCode* )randomStock;
@end
