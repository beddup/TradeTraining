//
//  TTStockCodeHelper.m
//  TradeTraining
//
//  Created by Amay on 3/20/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTStockCodeHelper.h"
//#import <BmobSDK/Bmob.h>
#import "AppDelegate.h"
#import "StockCode+CoreDataProperties.h"
#import "TTDefines.h"
@implementation TTStockCodeHelper

+(instancetype)stockCodeHelper{
    return nil;
}

+(void)loadStockCode{

    NSString* localPath = [[NSBundle mainBundle] pathForResource:@"stockcode" ofType:@"csv"];
    NSString* codesString = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:NULL];
    NSArray* codes = [codesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    // delete data in core data
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"StockCode"];
    NSError *error = nil;
    NSManagedObjectContext* context = [((AppDelegate*)[UIApplication sharedApplication].delegate) managedObjectContext];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if(fetchedObjects.count > 0){
        return;
    }

    for (NSString* code in codes) {
        NSArray* components = [code componentsSeparatedByString:@","];
        NSLog(@"%@",components);
        StockCode* stockCode = [NSEntityDescription insertNewObjectForEntityForName:@"StockCode" inManagedObjectContext:context];
        stockCode.code = components[0];
        stockCode.name = components[1];
        stockCode.pinyin = components[2];
        stockCode.market = components[3];
    }
    [((AppDelegate *)[UIApplication sharedApplication].delegate) saveContext];

}

//+(void)updateStockCode{
//
//    NSInteger versionNumber = [[NSUserDefaults standardUserDefaults] integerForKey:TTStokCodeVersion];
//
//    BmobQuery* query = [[BmobQuery alloc] initWithClassName:@"BeddupDataVersion"];
//    [query findObjectsInBackgroundWithBlock:^(NSArray *array, NSError *error) {
//
//        BmobObject* object = [array firstObject];
//        NSNumber* version = [object objectForKey:@"version"];
//        if (version.integerValue > versionNumber) {
//
//            // download the new stock code file
//            BmobFile* file =(BmobFile *)[object objectForKey:@"file"];
//            NSURL* fileURL = [NSURL URLWithString:file.url];
//            dispatch_queue_t fileDownLoadQueue = dispatch_queue_create("fileDownLoadQueue", NULL);
//            dispatch_async(fileDownLoadQueue, ^{
//                NSString* codesString = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
//                NSString* localPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"stockcode.csv"];
//                [codesString writeToFile:localPath atomically:NO encoding:NSUTF8StringEncoding error:NULL];
//                NSArray* codes = [codesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
//
//                // delete data in core data
//                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"StockCode"];
//                NSError *error = nil;
//                NSManagedObjectContext* context = [((AppDelegate*)[UIApplication sharedApplication].delegate) managedObjectContext];
//                NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
//                for (StockCode* object in fetchedObjects) {
//                    [context deleteObject:object];
//                    NSLog(@"delete");
//                }
//
//                for (NSString* code in codes) {
//                    NSArray* components = [code componentsSeparatedByString:@","];
//                    NSLog(@"%@",components);
//                    StockCode* stockCode = [NSEntityDescription insertNewObjectForEntityForName:@"StockCode" inManagedObjectContext:context];
//                    stockCode.code = components[0];
//                    stockCode.name = components[1];
//                    stockCode.pinyin = components[2];
//                    stockCode.market = components[3];
//                }
//                [((AppDelegate *)[UIApplication sharedApplication].delegate) saveContext];
//                [[NSUserDefaults standardUserDefaults] setInteger:version.integerValue forKey:TTStokCodeVersion];
//                [[NSUserDefaults standardUserDefaults] synchronize];
//
//            });
//
//        }
//    }];
//    
//}

+(NSArray* )searchStock:(NSString*)keyword{

    NSInteger versionNumber = [[NSUserDefaults standardUserDefaults] integerForKey:TTStokCodeVersion];
    if (versionNumber == 0) {
        return @[];
    }

    NSManagedObjectContext* context = ((AppDelegate* )[UIApplication sharedApplication].delegate).managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"StockCode"];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR code CONTAINS[cd] %@ OR pinyin CONTAINS[cd] %@",keyword,keyword,keyword];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"code"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        return nil;
    }
    return fetchedObjects;
    
}

+(StockCode* )randomStock{

    NSManagedObjectContext* context = ((AppDelegate* )[UIApplication sharedApplication].delegate).managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"StockCode"];
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        return nil;
    }
    if (fetchedObjects.count > 0) {
        NSInteger index = arc4random() % fetchedObjects.count;
        return fetchedObjects[index];
    }
    return nil;

}


@end
