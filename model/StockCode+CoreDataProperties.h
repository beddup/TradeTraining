//
//  StockCode+CoreDataProperties.h
//  
//
//  Created by Amay on 3/20/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "StockCode.h"

NS_ASSUME_NONNULL_BEGIN

@interface StockCode (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *code;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *market;
@property (nullable, nonatomic, retain) NSString *pinyin;

@end

NS_ASSUME_NONNULL_END
