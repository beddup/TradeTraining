//
//  TTRecordInfoView.h
//  TradeTraining
//
//  Created by Amay on 4/2/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TTKLineRecord;
@interface TTRecordInfoView : UIView

@property(strong,nonatomic) TTKLineRecord* record;
@property(nonatomic) BOOL showDate;

@end
