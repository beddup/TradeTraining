//
//  StockCode.m
//  
//
//  Created by Amay on 3/20/16.
//
//

#import "StockCode.h"

@implementation StockCode

// Insert code here to add functionality to your managed object subclass
-(NSString*) completeCode{
    return [NSString stringWithFormat:@"%@.%@",self.code,self.market];
}


@end
