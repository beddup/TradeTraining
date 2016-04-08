//
//  TTRecordInfoView.m
//  TradeTraining
//
//  Created by Amay on 4/2/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTRecordInfoView.h"
#import "NSDate+Extension.h"
#import "TTKLineRecord.h"
@interface TTRecordInfoView()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *openLabel;
@property (weak, nonatomic) IBOutlet UILabel *highLabel;
@property (weak, nonatomic) IBOutlet UILabel *lowLabel;
@property (weak, nonatomic) IBOutlet UILabel *closeLabel;
@property (weak, nonatomic) IBOutlet UILabel *zhangdieLabel;
@property (weak, nonatomic) IBOutlet UILabel *zhangdiefuLabel;
@property (weak, nonatomic) IBOutlet UILabel *volumnLabel;

@property(strong,nonatomic)NSDateFormatter* dateFormatter;

@end


@implementation TTRecordInfoView

-(UIColor*) colorForPrice:(float)price{
    if (self.record.previousClosePrice > price) {
        return [UIColor greenColor];
    }else if (self.record.previousClosePrice < price){
        return [UIColor redColor];
    }else{
        return [UIColor blackColor];
    }
}

-(void)setRecord:(TTKLineRecord *)record{
    _record = record;

    self.dateLabel.text  = self.showDate ? [self.dateFormatter stringFromDate:record.date] : nil;
    
    self.openLabel.text = [NSString stringWithFormat:@"%.2f",record.openPrice];
    self.openLabel.textColor = [self colorForPrice:record.openPrice];

    self.closeLabel.text = [NSString stringWithFormat:@"%.2f",record.closePrice];
    self.closeLabel.textColor = [self colorForPrice:record.closePrice];

    self.highLabel.text = [NSString stringWithFormat:@"%.2f",record.maxPrice];
    self.highLabel.textColor = [self colorForPrice:record.maxPrice];

    self.lowLabel.text = [NSString stringWithFormat:@"%.2f",record.minPrice];
    self.lowLabel.textColor = [self colorForPrice:record.minPrice];

    self.zhangdieLabel.text = [NSString stringWithFormat:@"%.2f",record.closePrice - record.previousClosePrice];
    self.zhangdieLabel.textColor = self.closeLabel.textColor;

    self.zhangdiefuLabel.text = [NSString stringWithFormat:@"%.2f%%",(record.closePrice - record.previousClosePrice) / record.previousClosePrice * 100];
    self.zhangdiefuLabel.textColor = self.closeLabel.textColor;

    self.volumnLabel.text = [NSString stringWithFormat:@"%.2f百万",record.volumn * 1.0 / 1000];

}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    self.showDate = YES;
    
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.layer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8].CGColor;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = 0.5;

    self.dateFormatter  = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];


}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

@end
