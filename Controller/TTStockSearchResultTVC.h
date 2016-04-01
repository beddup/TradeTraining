//
//  TTStockSearchResultTVC.h
//  TradeTraining
//
//  Created by Amay on 3/31/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StockCode;
@protocol TTStockSearchResultTVCDelegate <NSObject>

// called when selected Stock
-(void)didSelectStock:(StockCode*)stock;

@end

@interface TTStockSearchResultTVC : UITableViewController<UISearchResultsUpdating>

@property(weak,nonatomic) id <TTStockSearchResultTVCDelegate> delegate;

@end
