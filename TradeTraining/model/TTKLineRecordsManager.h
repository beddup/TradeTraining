//
//  TTKLineRecordsManager.h
//  TradeTraining
//
//  Created by Amay on 3/20/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTDefines.h"
#import "TTKLineRecord.h"

@interface TTKLineRecordsManager : NSObject

@property(strong,nonatomic) NSString* stockCode;

@property(nonatomic) TTMAType maType;

@property(nonatomic) NSString* kLineType;


-(void)getRecordsFrom:(NSDate* )fromDate
                   to:(NSDate*)toDate
    completionHandler:(void(^)(NSArray* records,NSString* type)) completionHander;

@end
