//
//  StockCode.h
//  
//
//  Created by Amay on 3/20/16.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface StockCode : NSManagedObject

// Insert code here to declare functionality of your managed object subclass
@property(strong,readonly,nonatomic) NSString* completeCode;

@end

NS_ASSUME_NONNULL_END

#import "StockCode+CoreDataProperties.h"
