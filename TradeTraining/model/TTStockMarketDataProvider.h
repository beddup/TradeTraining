//
//  TTFetchStockData.h
//  TradeTraining
//
//  Created by Amay on 3/18/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTDefines.h"

@interface TTStockMarketDataProvider : NSObject


-(void)getHistoryData:(NSString*) completeStockCode
                 From:(NSDate*) fromDate
                   to:(NSDate*) toDate
                 type:(NSString* )dataType
              success:(void(^)(NSArray* kLineRecords, NSString* kType))success
              failure:(void(^)(NSError*))fail;

@end
