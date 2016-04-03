//
//  TTKLineChart.m
//  TradeTraining
//
//  Created by Amay on 3/21/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTKLineChart.h"
#import "TTKLineRecordsManager.h"
#import "NSDate+Extension.h"
#import "TTDefines.h"
#import "TTRecordInfoView.h"
#import "TTKLineChartFrameView.h"

@interface TTKLineChart()

// value for drawing
@property(nonatomic) CGFloat axisMaxPrice;
@property(nonatomic) CGFloat axisMinPrice;
@property(nonatomic) NSInteger maxVolumn;

@property(nonatomic) CGFloat kLineAreaHeight;
@property(nonatomic) CGFloat heightAndPriceAspect;
@property(nonatomic) CGFloat maxVolumHegiht;
@property(nonatomic) CGFloat KWidth; // width of k line
@property(nonatomic) CGFloat KInterSpace; // space between two k line

// coclor for drawing

@property(strong,nonatomic) UIColor* chartFrameColor;
@property(strong,nonatomic) UIColor* referencePriceColor;
@property(strong,nonatomic) UIColor* referencePriceLineColor;
@property(strong,nonatomic) UIColor* klineIncreaseColor;
@property(strong,nonatomic) UIColor* klineDecreaseColor;
@property(strong,nonatomic) UIColor* klineNotChangeColor;
@property(strong,nonatomic) UIColor* MA5Color;
@property(strong,nonatomic) UIColor* MA10Color;
@property(strong,nonatomic) UIColor* MA20Color;
@property(strong,nonatomic) UIColor* focusedCrossLineColor;
@property(strong,nonatomic) UIColor* dateColor;

// paragraph stye
@property(strong,nonatomic)NSMutableParagraphStyle* alignmentCenter;
@property(strong,nonatomic)NSMutableParagraphStyle* alignmentRight;

// the position X of the last visible k line in the chart
@property(nonatomic) CGFloat lastVisibleKLineX;
// the index of the last visible k line record
@property(nonatomic) NSInteger lastVisibleRecordIndex;


// the record where long pressed happened;
@property(weak, nonatomic) TTRecordInfoView* recordInfoView;
@property(strong, nonatomic) TTKLineRecord* focusedRecord;
@property(strong, nonatomic) UILongPressGestureRecognizer* longPressGesture;
@property(strong, nonatomic) UIBezierPath* crossLine;

@property(weak, nonatomic)UILabel* maDisplayLabel;

@property(weak, nonatomic) UIActivityIndicatorView* fetchDateIndicator;
@property(weak, nonatomic) TTKLineChartFrameView* frameView;

// ma line
@property(strong,nonatomic)UIBezierPath* ma5;
@property(strong,nonatomic)UIBezierPath* ma10;
@property(strong,nonatomic)UIBezierPath* ma20;

// date line

@property(strong,nonatomic)UIBezierPath* dateLine;

@end


@implementation TTKLineChart

#pragma mark - Properties
-(void)setKLineType:(NSString *)kLineType{

    if (_kLineType != kLineType) {

        // if k line type change, records need reloaded
        _kLineType = kLineType;
        self.records = nil;
        [self getMoreKLineRecords];
    }
}

-(void)setLastVisibleKLineX:(CGFloat)lastVisibleKLineX{

    if (_lastVisibleKLineX != lastVisibleKLineX) {
        _lastVisibleKLineX = lastVisibleKLineX;
        [self calculateMaxPriceAndMaxVolumn];
        if (self.records.count) {
            [self setNeedsDisplay];
        }
    }
}

-(void)setFocusedRecord:(TTKLineRecord *)focusedRecord{
    if (![focusedRecord.date isSameDay:_focusedRecord.date]) {
        _focusedRecord = focusedRecord;
        [self updateMAInfo];
        self.recordInfoView.hidden = (focusedRecord == nil);
        if (focusedRecord) {
            self.recordInfoView.showDate = self.showDate;
            self.recordInfoView.record = self.focusedRecord;
        }
        [self updateFocusedRecordInfo];
        [self setNeedsDisplay];
    }
}

-(void)setRecords:(NSArray *)records{

    _records = records;

    [self.fetchDateIndicator removeFromSuperview];
    self.fetchDateIndicator = nil;

    self.lastVisibleRecordIndex = 0;
    [self calculateMaxPriceAndMaxVolumn];

    [self updateMAInfo];

    if (self.records.count) {
        [self setNeedsDisplay];
    }

}

-(void)setStockCode:(NSString *)stockCode{

        _stockCode = stockCode;
        self.records = nil;
        [self getMoreKLineRecords];
    
}
#pragma mark - Get k line records

-(void)getMoreKLineRecords{

    // get one more year records for day k ,  5 more year for week k and all records for month k
    NSDate* fromDate = nil;
    NSDate* now = [NSDate date];

    NSDate* earlistDate = self.records.count > 0 ? ((TTKLineRecord*)[self.records lastObject]).date : now;
    if ([self.kLineType isEqualToString:TTKlineTypeDay]) {
        fromDate  = [earlistDate offsetYears:-1];
    }else if ([self.kLineType isEqualToString:TTKlineTypeWeek]){
        fromDate  = [earlistDate offsetYears:-5];
    }else{
        fromDate = [NSDate distantPast];
    }

    [self showFetchDateIndicatorAtCenter:self.center];

    [self.dataSource getRecordsOfStock:self.stockCode
                                  From:fromDate
                                    to:now
                             kLineType:self.kLineType
                      completionHander:^(NSArray *records) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              self.records = records;
                          });
                      }];

}

-(void)showFetchDateIndicatorAtCenter:(CGPoint)center{
    if (!self.fetchDateIndicator) {
        UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.bounds = CGRectMake(0, 0, 100, 100);
        [self addSubview:indicator];
        self.fetchDateIndicator = indicator;
        [self.fetchDateIndicator startAnimating];
    }
    self.fetchDateIndicator.center = center;
    
}

#pragma mark - CalcutionForDrawing
-(void)calculateMaxPriceAndMaxVolumn{

    if(!self.records.count) {
        return;
    }


    NSInteger recordIndex = self.lastVisibleRecordIndex;
    CGFloat x = self.lastVisibleKLineX;

    CGFloat maxPrice = 0;
    CGFloat minPrice = ((TTKLineRecord*)self.records[0]).minPrice;
    CGFloat maxVolumn = 0;

    // calculate the axisMaxPrice and axisMinPrice and maxVolumn, according to current visible records
    while ( x > - self.KWidth ) {

            TTKLineRecord * record = self.records[recordIndex];
            if (record.maxPrice > maxPrice) {
                maxPrice =  record.maxPrice;
            }
            if (record.minPrice < minPrice) {
                minPrice = record.minPrice ;
            }
            if (record.volumn > maxVolumn) {
                maxVolumn = record.volumn;
            }

        x -= self.KInterSpace + self.KWidth;
        recordIndex += 1;

        if (recordIndex >= self.records.count && !self.fetchDateIndicator && ![self.kLineType isEqualToString:TTKlineTypeMonth]){
            [self getMoreKLineRecords];
            break;
        }
    }

    self.axisMaxPrice = maxPrice * 1.05 ;
    self.axisMinPrice  =  minPrice * 0.95;
    self.maxVolumn = maxVolumn * 1.1;
    self.heightAndPriceAspect = self.kLineAreaHeight / (self.axisMaxPrice - self.axisMinPrice);

    // calculate ma line and k line
    [self.ma5 removeAllPoints];
    [self.ma10 removeAllPoints];
    [self.ma20 removeAllPoints];

    recordIndex = self.lastVisibleRecordIndex;
     x = self.lastVisibleKLineX;

    while ( x > - self.KWidth ) {
        TTKLineRecord * record = self.records[recordIndex];

        if (record.MA5 > 0) {
            if (recordIndex == self.lastVisibleRecordIndex) {
                [self.ma5 moveToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA5) * self.heightAndPriceAspect)];
            }
            [self.ma5 addLineToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA5) * self.heightAndPriceAspect)];
        }
        if (record.MA10 > 0) {
            if (recordIndex == self.lastVisibleRecordIndex) {
                [self.ma10 moveToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA10) * self.heightAndPriceAspect)];
            }
            [self.ma10 addLineToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA10) * self.heightAndPriceAspect)];
        }
        if (record.MA20 > 0) {
            if (recordIndex == self.lastVisibleRecordIndex) {
                [self.ma20 moveToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA20) * self.heightAndPriceAspect)];
            }
            [self.ma20 addLineToPoint:CGPointMake(x +self.KWidth / 2, (self.axisMaxPrice - record.MA20) * self.heightAndPriceAspect)];
        }

        x -= self.KInterSpace + self.KWidth;
        recordIndex += 1;
    }

}

#pragma mark - Draw
static CGFloat KlineAreaHeightRatio = 0.8;
static CGFloat KlineAndVolumSpace = 15.0;
static NSInteger AxisPriceZoneCount = 4;
static CGFloat RecordInfoDisplayWidth = 140;
static CGFloat RecordInfoDisplayHeight = 160;

static CGFloat MADisplayZoneHeight = 25;

-(void)drawReferencePrice{

    for (NSInteger index = 1; index < AxisPriceZoneCount; index++) {
        CGFloat referenceLineY = self.kLineAreaHeight / AxisPriceZoneCount * index;
        NSString* price = [NSString stringWithFormat:@"%.2f",self.axisMaxPrice - (self.axisMaxPrice - self.axisMinPrice) / AxisPriceZoneCount * index];
        [price drawAtPoint:CGPointMake(1, referenceLineY - 15) withAttributes:@{NSForegroundColorAttributeName : self.referencePriceColor}];

    }
}

-(void)updateFocusedRecordInfo{
        if (!self.focusedRecord) {
            return;
        }
        CGFloat locationX = [self.longPressGesture locationInView:self].x;
        NSInteger offset =(NSInteger)((self.lastVisibleKLineX + self.KWidth / 2 - locationX) / (self.KWidth + self.KInterSpace) + 0.5);
        CGFloat adjustedX = (self.lastVisibleKLineX + self.KWidth / 2) - offset * (self.KWidth + self.KInterSpace);

        [self.crossLine removeAllPoints];
        [self.crossLine moveToPoint:CGPointMake(adjustedX, 0)];
        [self.crossLine addLineToPoint:CGPointMake(adjustedX, self.kLineAreaHeight)];
        CGFloat locationY = (self.axisMaxPrice - self.focusedRecord.closePrice) * self.heightAndPriceAspect;
        [self.crossLine moveToPoint:CGPointMake(0, locationY)];
        [self.crossLine addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds), locationY)];

        if (locationX > CGRectGetMidX(self.bounds)) {
            self.recordInfoView.frame = CGRectMake(0, MADisplayZoneHeight,RecordInfoDisplayWidth,RecordInfoDisplayHeight);
        }
        else{
            self.recordInfoView.frame = CGRectMake(CGRectGetMaxX(self.bounds) - RecordInfoDisplayWidth, MADisplayZoneHeight,RecordInfoDisplayWidth,RecordInfoDisplayHeight);
        }

}


-(void)updateMAInfo{
    // draw ma string
    TTKLineRecord* record = self.focusedRecord  ? self.focusedRecord : [self.records firstObject];

    NSMutableAttributedString* maString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"MA5: %.2f   ",record.MA5] attributes:@{NSForegroundColorAttributeName:self.MA5Color}];
    [maString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"MA10: %.2f   ",record.MA10] attributes:@{NSForegroundColorAttributeName:self.MA10Color}]];
    [maString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"MA20: %.2f   ",record.MA20] attributes:@{NSForegroundColorAttributeName:self.MA20Color}]];
    [self.maDisplayLabel setAttributedText:maString];
}

-(void)drawMALine{

    // draw ma line
    [self.MA5Color setStroke];
    [self.ma5 stroke];
    [self.MA10Color setStroke];
    [self.ma10 stroke];
    [self.MA20Color setStroke];
    [self.ma20 stroke];

}

- (void)drawRect:(CGRect)rect {

    [self drawReferencePrice];
    [self drawMALine];

    // draw focused cross line
    if (self.focusedRecord) {
        [self.focusedCrossLineColor setStroke];
        [self.crossLine stroke];
    }

    // draw K line and volumn
    CGFloat x = self.lastVisibleKLineX;
    NSInteger recordIndex = self.lastVisibleRecordIndex;
    [self.dateLine removeAllPoints];
    while (x > -self.KWidth) {

        if (recordIndex >= self.records.count) {
            return;
        }

        TTKLineRecord * record = self.records[recordIndex];

        CGFloat maxY = (self.axisMaxPrice - record.maxPrice) * self.heightAndPriceAspect;
        CGFloat openY = (self.axisMaxPrice - record.openPrice) * self.heightAndPriceAspect;
        CGFloat closeY = (self.axisMaxPrice - record.closePrice) * self.heightAndPriceAspect;
        CGFloat minY = (self.axisMaxPrice - record.minPrice) * self.heightAndPriceAspect;

        UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectMake(x, openY < closeY ? openY : closeY , self.KWidth, fabs(openY - closeY))];
        [path moveToPoint:CGPointMake(x + self.KWidth / 2, maxY)];
        [path addLineToPoint:CGPointMake(x + self.KWidth / 2, minY)];

        CGFloat volumnHeight = 1.0 * record.volumn / self.maxVolumn * self.maxVolumHegiht;
        UIBezierPath* volumnPath = [UIBezierPath bezierPathWithRect:CGRectMake(x, CGRectGetMaxY(rect) - volumnHeight, self.KWidth, volumnHeight)];
        [path appendPath:volumnPath];

        if (record.openPrice > record.closePrice) {
            [self.klineDecreaseColor setFill]; [self.klineDecreaseColor setStroke];
        }else if (record.openPrice < record.closePrice ){
            [self.klineIncreaseColor setFill]; [self.klineIncreaseColor setStroke];
        }else{
            [self.klineNotChangeColor setFill]; [self.klineNotChangeColor setStroke];
        }

        path.lineWidth = 1.0;
        [path stroke];
        [path fill];

        // draw date
        if (recordIndex > 0 && self.showDate) {
            NSDate* previousRecordDate = ((TTKLineRecord*)self.records[recordIndex - 1]).date;
            NSDate* theDate = record.date;
            NSString* dateString = nil;
            if ([self.kLineType isEqualToString:TTKlineTypeDay]){
                if ([previousRecordDate month] != [theDate month] || [previousRecordDate year] != [theDate year]) {
                    dateString = [NSString stringWithFormat:@"%lu-%lu",(unsigned long)[previousRecordDate year],(unsigned long)[previousRecordDate month]];;
                }
            }else if ([self.kLineType isEqualToString:TTKlineTypeWeek]){
                if ([previousRecordDate year] != [theDate year]) {
                    dateString = [NSString stringWithFormat:@"%lu-%lu",(unsigned long)[previousRecordDate year],(unsigned long)[previousRecordDate month]];;
                }else if([previousRecordDate month] != [theDate month]){
                    dateString = [NSString stringWithFormat:@"%lu",(unsigned long)[previousRecordDate month]];;
                }
            }else {
                if ([previousRecordDate year] != [theDate year]) {
                    dateString = [NSString stringWithFormat:@"%lu",(unsigned long)[previousRecordDate year]];;
                }
            }
            if (dateString) {
                //draw date string
                [dateString drawWithRect:CGRectMake(x + self.KWidth / 2 + self.KWidth + self.KInterSpace - 50, self.kLineAreaHeight, 100, KlineAndVolumSpace) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSForegroundColorAttributeName:self.dateColor,NSParagraphStyleAttributeName : self.alignmentCenter } context:nil];

                // draw date line
                [self.dateLine moveToPoint:CGPointMake(x + self.KWidth / 2 + self.KWidth + self.KInterSpace , self.kLineAreaHeight)];
                [self.dateLine addLineToPoint:CGPointMake(x + self.KWidth / 2 + self.KWidth + self.KInterSpace, self.kLineAreaHeight - 5)];
            }
        }
//
        x -= self.KInterSpace + self.KWidth;
        recordIndex += 1;
    }

    [self.chartFrameColor setStroke];
    [self.dateLine stroke];

}


#pragma mark - Gestures;
-(void)pinch:(UIPinchGestureRecognizer* )pinchGesture{

    if (!self.records.count) {
        return;
    }

    CGFloat scale = pinchGesture.scale;
    if ((self.KWidth > 30 && scale > 1.0) || (self.KWidth < 5 && scale < 1.0)) {
        return;
    }

    self.KWidth *= scale;
    self.KInterSpace *= scale;

    CGFloat x = CGRectGetMidX(self.bounds) +  (self.lastVisibleKLineX -  CGRectGetWidth(self.bounds) / 2) * scale;

    [self adjustLastVisibleKlineX:x];

    pinchGesture.scale = 1.0;

}

-(void)pan:(UIPanGestureRecognizer*)panGesture{

    if (!self.records.count) {
        return;
    }
    if (panGesture.state == UIGestureRecognizerStateChanged) {
        CGFloat translationX = [panGesture translationInView:self].x;
        CGFloat x = self.lastVisibleKLineX + translationX;
        [self adjustLastVisibleKlineX:x];
        [panGesture setTranslation:CGPointZero inView:self];
    }else if (panGesture.state  == UIGestureRecognizerStateEnded ||
              panGesture.state == UIGestureRecognizerStateCancelled){
        self.focusedRecord = nil;
    }

}

-(void)adjustLastVisibleKlineX:(CGFloat)x{

    while (x >= CGRectGetMaxX(self.bounds) && self.lastVisibleRecordIndex < self.records.count - 1) {
        x -= self.KInterSpace + self.KWidth;
        self.lastVisibleRecordIndex ++;
    }

    while (x < CGRectGetMaxX(self.bounds) - self.KInterSpace -self.KWidth && self.lastVisibleRecordIndex > 0) {
        x += self.KInterSpace + self.KWidth;
        self.lastVisibleRecordIndex --;
    }
    self.lastVisibleKLineX = x;

}


-(void)longPress:(UILongPressGestureRecognizer*)longPress{

    if (!self.records.count) {
        return;
    }

    if (longPress.state  == UIGestureRecognizerStateBegan ||
        longPress.state  == UIGestureRecognizerStateChanged) {
        CGFloat locationX = [longPress locationInView:self].x;

        if (locationX >= self.lastVisibleKLineX) {
           self.focusedRecord = self.records[self.lastVisibleRecordIndex];
        }else{
            NSInteger offset =(NSInteger)((self.lastVisibleKLineX + self.KWidth / 2 - locationX) / (self.KWidth + self.KInterSpace) + 0.5);
            self.focusedRecord = self.records[self.lastVisibleRecordIndex + offset];
        }

    }else if (longPress.state == UIGestureRecognizerStateEnded ||
              longPress.state == UIGestureRecognizerStateCancelled||
              longPress.state == UIGestureRecognizerStateFailed){
        self.focusedRecord = nil;
    }

}

#pragma  mark - setup

-(void)layoutSubviews{

    self.kLineAreaHeight = CGRectGetHeight(self.bounds) * KlineAreaHeightRatio;
    self.maxVolumHegiht = CGRectGetHeight(self.bounds) * (1 - KlineAreaHeightRatio) - KlineAndVolumSpace;
    self.fetchDateIndicator.center = self.center;

    self.frameView.frame = self.bounds;

    if (self.lastVisibleKLineX == -5201314 ) {
        // initail position
        _lastVisibleKLineX = CGRectGetWidth(self.bounds) * 2 / 3;
    }else{
        self.lastVisibleKLineX = CGRectGetMaxX(self.bounds) - self.KWidth - self.KInterSpace;
    }
}

-(void)awakeFromNib{
    [self setup];
}

-(void)setup{


    self.backgroundColor = [UIColor clearColor];

    self.axisMaxPrice = 0;
    self.axisMinPrice = 0;
    self.maxVolumn = 0;

    _KWidth = 10.0;
    _KInterSpace = 4.0;
    _lastVisibleKLineX = -5201314;
    _kLineType = TTKlineTypeDay;
    _showDate = YES;


    _referencePriceColor = [UIColor lightGrayColor];
    _klineIncreaseColor = [UIColor redColor];
    _klineDecreaseColor = [UIColor greenColor];
    _klineNotChangeColor = [UIColor blackColor];
    _MA5Color = [UIColor orangeColor];
    _MA10Color = [UIColor brownColor];
    _MA20Color = [UIColor purpleColor];
    _focusedCrossLineColor = [UIColor darkGrayColor];
    _dateColor = [UIColor darkGrayColor];

    _alignmentCenter = [[NSMutableParagraphStyle alloc] init];
    _alignmentCenter.alignment = NSTextAlignmentCenter;

    _alignmentRight = [[NSMutableParagraphStyle alloc] init];
    _alignmentRight.alignment = NSTextAlignmentRight;

    // add pinch and pan gesture
    UIPinchGestureRecognizer* pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self addGestureRecognizer:pinchGesture];

    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:panGesture];

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:longPressGesture];
    longPressGesture.numberOfTouchesRequired  = 1;
    self.longPressGesture = longPressGesture;


    // chart frame
    TTKLineChartFrameView* frameView = [[TTKLineChartFrameView alloc]initWithFrame:self.bounds];
    [self addSubview:frameView];
    self.frameView = frameView;
    frameView.KlineAreaHeightRatio = KlineAreaHeightRatio;
    frameView.klineAndVolumSpace = KlineAndVolumSpace;
    frameView.axisPriceZoneCount = AxisPriceZoneCount;


    //ma info label
    UILabel* MAInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), MADisplayZoneHeight)];
    MAInfoLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    [self addSubview:MAInfoLabel];
    self.maDisplayLabel = MAInfoLabel;

    // focused record info
    TTRecordInfoView* view = [[[NSBundle mainBundle] loadNibNamed:@"TTRecordInfoView" owner:nil options:nil] lastObject];
    [self addSubview:view];
    view.bounds = CGRectMake(0,0, RecordInfoDisplayWidth, RecordInfoDisplayHeight);
    self.recordInfoView = view;
    view.hidden = YES;

    self.crossLine = [UIBezierPath bezierPath];
    self.crossLine.lineWidth = 1.0;

    // ma path
    self.ma5 = [UIBezierPath bezierPath];
    self.ma5.lineWidth = 0.5;
    self.ma5.lineJoinStyle = kCGLineJoinBevel;

    self.ma10 = [UIBezierPath bezierPath];
    self.ma10.lineWidth = 0.5;
    self.ma10.lineJoinStyle = kCGLineJoinBevel;

    self.ma20 = [UIBezierPath bezierPath];
    self.ma20.lineWidth = 0.5;
    self.ma20.lineJoinStyle = kCGLineJoinBevel;

    // date line
    self.dateLine = [UIBezierPath bezierPath];
    self.dateLine.lineWidth = 0.5;


}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}




@end
