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
@property(strong, nonatomic) TTKLineRecord* focusedRecord;
@property(strong, nonatomic) UILongPressGestureRecognizer* longPressGesture;

@property(weak, nonatomic) UIActivityIndicatorView* fetchDateIndicator;

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

-(void)setKWidth:(CGFloat)KWidth{
    if (_KWidth != KWidth) {
        _KWidth = KWidth;
        [self setNeedsDisplay];
    }
}

-(void)setKInterSpace:(CGFloat)KInterSpace{
    if (_KInterSpace != KInterSpace) {
        _KInterSpace = KInterSpace;
        [self setNeedsDisplay];
    }
}

-(void)setLastVisibleKLineX:(CGFloat)lastVisibleKLineX{

    if (_lastVisibleKLineX != lastVisibleKLineX) {
        _lastVisibleKLineX = lastVisibleKLineX;
        [self calculateMaxPriceAndMaxVolumn];
        [self setNeedsDisplay];
    }
}

-(void)setFocusedRecord:(TTKLineRecord *)focusedRecord{
    if (![focusedRecord.date isSameDay:_focusedRecord.date]) {
        _focusedRecord = focusedRecord;
        [self setNeedsDisplay];
    }
}

-(void)setRecords:(NSArray *)records{

    _records = records;

    [self.fetchDateIndicator removeFromSuperview];
    self.fetchDateIndicator = nil;

    self.lastVisibleRecordIndex = 0;
    [self calculateMaxPriceAndMaxVolumn];

    [self setNeedsDisplay];

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

    // calculate the axisMaxPrice and axisMinPrice and maxVolumn, according to current visible records
    if(!self.records.count) {
        return;
    }
    NSInteger recordIndex = self.lastVisibleRecordIndex;
    CGFloat x = self.lastVisibleKLineX;

    CGFloat maxPrice = 0;
    CGFloat minPrice = ((TTKLineRecord*)self.records[0]).minPrice;
    CGFloat maxVolumn = 0;

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

}

#pragma mark - Draw
static CGFloat KlineAreaHeightRatio = 0.8;
static CGFloat KlineAndVolumSpace = 15.0;
static NSInteger AxisPriceZoneCount = 4;
static CGFloat RecordInfoDisplayWidth = 100;
static CGFloat MADisplayZoneHeight = 25;

-(void)drawChartFrame{

    // draw k line area frame
    UIBezierPath * kLineFrame = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.kLineAreaHeight)];
    kLineFrame.lineWidth = 0.5;
    [self.chartFrameColor setStroke];
    [kLineFrame stroke];

    // draw k line reference line and price
    UIBezierPath * referenceLine = [UIBezierPath bezierPath];
    referenceLine.lineWidth = 0.5;
    CGFloat lineDash[] = {3,2}  ;
    [referenceLine setLineDash:lineDash count:1 phase:1];
    for (NSInteger index = 1; index < AxisPriceZoneCount; index++) {
        CGFloat referenceLineY = self.kLineAreaHeight / AxisPriceZoneCount * index;
        [referenceLine moveToPoint:CGPointMake(0,  referenceLineY)];
        [referenceLine addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds), referenceLineY)];
        NSString* price = [NSString stringWithFormat:@"%.2f",self.axisMaxPrice - (self.axisMaxPrice - self.axisMinPrice) / AxisPriceZoneCount * index];
        [price drawAtPoint:CGPointMake(1, referenceLineY - 15) withAttributes:@{NSForegroundColorAttributeName : self.referencePriceColor}];

    }
    [self.referencePriceLineColor setStroke];
    [referenceLine stroke];

    // draw volumn Frame
    UIBezierPath* volumnFrame = [UIBezierPath bezierPathWithRect:CGRectMake(0, self.kLineAreaHeight + KlineAndVolumSpace, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - self.kLineAreaHeight - KlineAndVolumSpace)];
    volumnFrame.lineWidth = 0.5;
    [volumnFrame stroke];

}
-(void)drawFocusedRecordCrossLine{

    if (self.focusedRecord) {

        CGFloat locationX = [self.longPressGesture locationInView:self].x;
        NSInteger offset =(NSInteger)((self.lastVisibleKLineX + self.KWidth / 2 - locationX) / (self.KWidth + self.KInterSpace) + 0.5);
        CGFloat adjustedX = (self.lastVisibleKLineX + self.KWidth / 2) - offset * (self.KWidth + self.KInterSpace);

        UIBezierPath* crossLine = [UIBezierPath bezierPath];
        [crossLine moveToPoint:CGPointMake(adjustedX, 0)];
        [crossLine addLineToPoint:CGPointMake(adjustedX, self.kLineAreaHeight)];

        CGFloat locationY = (self.axisMaxPrice - self.focusedRecord.closePrice) * self.heightAndPriceAspect;
        [crossLine moveToPoint:CGPointMake(0, locationY)];
        [crossLine addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds), locationY)];
        [self.focusedCrossLineColor setStroke];
        [crossLine stroke];
    }
}
-(void)drawFocuesdRecordInfo{
    // draw focused record info
    if (self.focusedRecord) {

        CGFloat locationX = [self.longPressGesture locationInView:self].x;
        CGFloat focusedFrameX = 0;
        if (locationX > CGRectGetMidX(self.bounds)) {
            focusedFrameX = 0;
        }else{
            focusedFrameX = CGRectGetMaxX(self.bounds) - RecordInfoDisplayWidth;
        }
        UIBezierPath* focusedFrame = [UIBezierPath bezierPathWithRect:CGRectMake(focusedFrameX, MADisplayZoneHeight, RecordInfoDisplayWidth, self.kLineAreaHeight - MADisplayZoneHeight)];
        [[[UIColor whiteColor] colorWithAlphaComponent:0.9] setFill];
        [self.chartFrameColor setStroke];
        [focusedFrame stroke];
        [focusedFrame fill];

        // draw record Info

        CGFloat drawHeight = (self.kLineAreaHeight - MADisplayZoneHeight) / 8;
        if (self.showDate) {
            [[self.focusedRecord.date stringWithFormat:[NSDate ymdFormat]] drawWithRect:CGRectMake(focusedFrameX, MADisplayZoneHeight, RecordInfoDisplayWidth, drawHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSParagraphStyleAttributeName:self.alignmentCenter} context:nil];
        }
        UIColor* displayColor = nil;

        displayColor = self.focusedRecord.openPrice > self.focusedRecord.previousClosePrice ? self.klineIncreaseColor : (self.focusedRecord.openPrice < self.focusedRecord.previousClosePrice ? self.klineDecreaseColor : self.klineNotChangeColor);
        [@"开盘价" drawAtPoint: CGPointMake(focusedFrameX + 2, MADisplayZoneHeight + drawHeight) withAttributes:nil];
        [[NSString stringWithFormat:@"%.2f ",self.focusedRecord.openPrice] drawWithRect:CGRectMake(focusedFrameX - 2, MADisplayZoneHeight + drawHeight * 1, RecordInfoDisplayWidth, drawHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSParagraphStyleAttributeName:self.alignmentRight,NSForegroundColorAttributeName:displayColor} context:nil];;

        displayColor = self.focusedRecord.maxPrice > self.focusedRecord.previousClosePrice ? self.klineIncreaseColor : (self.focusedRecord.maxPrice < self.focusedRecord.previousClosePrice ? self.klineDecreaseColor : self.klineNotChangeColor);
        [@"最高价" drawAtPoint: CGPointMake(focusedFrameX + 2, MADisplayZoneHeight + drawHeight * 2) withAttributes:nil];
        [[NSString stringWithFormat:@"%.2f ",self.focusedRecord.maxPrice] drawWithRect:CGRectMake(focusedFrameX - 2, MADisplayZoneHeight + drawHeight * 2, RecordInfoDisplayWidth, drawHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSParagraphStyleAttributeName:self.alignmentRight,NSForegroundColorAttributeName:displayColor} context:nil];;

        displayColor = self.focusedRecord.minPrice > self.focusedRecord.previousClosePrice ? self.klineIncreaseColor : (self.focusedRecord.minPrice < self.focusedRecord.previousClosePrice ? self.klineDecreaseColor : self.klineNotChangeColor);
        [@"最低价" drawAtPoint: CGPointMake(focusedFrameX + 2, MADisplayZoneHeight + drawHeight * 3) withAttributes:nil];
        [[NSString stringWithFormat:@"%.2f ",self.focusedRecord.minPrice] drawWithRect:CGRectMake(focusedFrameX - 2, MADisplayZoneHeight + drawHeight * 3, RecordInfoDisplayWidth, drawHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSParagraphStyleAttributeName:self.alignmentRight,NSForegroundColorAttributeName:displayColor} context:nil];;

        displayColor = self.focusedRecord.closePrice > self.focusedRecord.previousClosePrice ? self.klineIncreaseColor : (self.focusedRecord.closePrice < self.focusedRecord.previousClosePrice ? self.klineDecreaseColor : self.klineNotChangeColor);
        [@"收盘价" drawAtPoint: CGPointMake(focusedFrameX + 2, MADisplayZoneHeight + drawHeight * 4) withAttributes:nil];
        [[NSString stringWithFormat:@"%.2f ",self.focusedRecord.closePrice] drawWithRect:CGRectMake(focusedFrameX - 2, MADisplayZoneHeight + drawHeight * 4, RecordInfoDisplayWidth, drawHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSParagraphStyleAttributeName:self.alignmentRight,NSForegroundColorAttributeName:displayColor} context:nil];;


        [@"涨跌额" drawAtPoint: CGPointMake(focusedFrameX + 2, MADisplayZoneHeight + drawHeight * 5) withAttributes:nil];
        [[NSString stringWithFormat:@"%.2f ",self.focusedRecord.closePrice - self.focusedRecord.previousClosePrice] drawWithRect:CGRectMake(focusedFrameX - 2, MADisplayZoneHeight + drawHeight * 5, RecordInfoDisplayWidth, drawHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSParagraphStyleAttributeName:self.alignmentRight,NSForegroundColorAttributeName:displayColor} context:nil];;

        [@"涨跌幅" drawAtPoint: CGPointMake(focusedFrameX + 2, MADisplayZoneHeight + drawHeight * 6) withAttributes:nil];
        [[NSString stringWithFormat:@"%.2f%% ",(self.focusedRecord.closePrice - self.focusedRecord.previousClosePrice) / self.focusedRecord.previousClosePrice * 100 ] drawWithRect:CGRectMake(focusedFrameX - 2 , MADisplayZoneHeight + drawHeight * 6, RecordInfoDisplayWidth, drawHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSParagraphStyleAttributeName:self.alignmentRight,NSForegroundColorAttributeName:displayColor} context:nil];;

        [@"成交量" drawAtPoint: CGPointMake(focusedFrameX + 2, MADisplayZoneHeight + drawHeight * 7) withAttributes:nil];
        [[NSString stringWithFormat:@"%.2f百万 ",self.focusedRecord.volumn * 1.0 / 1000] drawWithRect:CGRectMake(focusedFrameX - 2, MADisplayZoneHeight + drawHeight * 7, RecordInfoDisplayWidth, drawHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSParagraphStyleAttributeName:self.alignmentRight} context:nil];;
    }
}

-(void)drawMAInfo{
    // draw ma string
    TTKLineRecord* record = self.focusedRecord  ? self.focusedRecord : [self.records firstObject];

    NSMutableAttributedString* maString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"MA5: %.2f   ",record.MA5] attributes:@{NSForegroundColorAttributeName:self.MA5Color}];
    [maString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"MA10: %.2f   ",record.MA10] attributes:@{NSForegroundColorAttributeName:self.MA10Color}]];
    [maString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"MA20: %.2f   ",record.MA20] attributes:@{NSForegroundColorAttributeName:self.MA20Color}]];
    [maString drawInRect:CGRectMake(0, 0, CGRectGetWidth(self.bounds), MADisplayZoneHeight)];
}

-(void)drawMALine{

    UIBezierPath* ma5 = [UIBezierPath bezierPath];
    ma5.lineWidth = 0.5;
    ma5.lineJoinStyle = kCGLineJoinBevel;
    UIBezierPath* ma10 = [UIBezierPath bezierPath];
    ma10.lineWidth = 0.5;
    ma10.lineJoinStyle = kCGLineJoinBevel;

    UIBezierPath* ma20 = [UIBezierPath bezierPath];
    ma20.lineWidth = 0.5;
    ma20.lineJoinStyle = kCGLineJoinBevel;
    
    CGFloat x = self.lastVisibleKLineX;
    NSInteger recordIndex = self.lastVisibleRecordIndex;

    while (x > -self.KWidth) {

        if (recordIndex >= self.records.count) {
            return;
        }
        TTKLineRecord * record = self.records[recordIndex];

        if (record.MA5 > 0) {
            if (recordIndex == self.lastVisibleRecordIndex) {
                [ma5 moveToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA5) * self.heightAndPriceAspect)];
            }
            [ma5 addLineToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA5) * self.heightAndPriceAspect)];
        }
        if (record.MA10 > 0) {
            if (recordIndex == self.lastVisibleRecordIndex) {
                [ma10 moveToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA10) * self.heightAndPriceAspect)];
            }
            [ma10 addLineToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA10) * self.heightAndPriceAspect)];
        }
        if (record.MA20 > 0) {
            if (recordIndex == self.lastVisibleRecordIndex) {
                [ma20 moveToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA20) * self.heightAndPriceAspect)];
            }
            [ma20 addLineToPoint:CGPointMake(x +self.KWidth / 2, (self.axisMaxPrice - record.MA20) * self.heightAndPriceAspect)];
        }
        [self.MA5Color setStroke];
        [ma5 stroke];
        [self.MA10Color setStroke];
        [ma10 stroke];
        [self.MA20Color setStroke];
        [ma20 stroke];

        x -= self.KInterSpace + self.KWidth;
        recordIndex += 1;

    }
}

- (void)drawRect:(CGRect)rect {

    if (!self.records.count) {
        return;
    }

    [self drawChartFrame];
    [self drawMALine];
    [self drawFocusedRecordCrossLine];

    // draw K line and volumn
    CGFloat x = self.lastVisibleKLineX;
    NSInteger recordIndex = self.lastVisibleRecordIndex;
    while (x > -self.KWidth) {

        if (recordIndex >= self.records.count) {
            return;
        }

        TTKLineRecord * record = self.records[recordIndex];

        CGFloat maxY = (self.axisMaxPrice - record.maxPrice) * self.heightAndPriceAspect;
        CGFloat openY = (self.axisMaxPrice - record.openPrice) * self.heightAndPriceAspect;
        CGFloat closeY = (self.axisMaxPrice - record.closePrice) * self.heightAndPriceAspect;
        CGFloat minY = (self.axisMaxPrice - record.minPrice) * self.heightAndPriceAspect;

        UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectMake(x, openY < closeY ? openY : closeY , self.KWidth, fabsf(openY - closeY))];
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
                    dateString = [NSString stringWithFormat:@"%d-%d",[previousRecordDate year],[previousRecordDate month]];;
                }
            }else if ([self.kLineType isEqualToString:TTKlineTypeWeek]){
                if ([previousRecordDate year] != [theDate year]) {
                    dateString = [NSString stringWithFormat:@"%d-%d",[previousRecordDate year],[previousRecordDate month]];;
                }else if([previousRecordDate month] != [theDate month]){
                    dateString = [NSString stringWithFormat:@"%d",[previousRecordDate month]];;
                }
            }else {
                if ([previousRecordDate year] != [theDate year]) {
                    dateString = [NSString stringWithFormat:@"%d",[previousRecordDate year]];;
                }
            }
            if (dateString) {
                //draw date string
                [dateString drawWithRect:CGRectMake(x + self.KWidth / 2 + self.KWidth + self.KInterSpace - 50, self.kLineAreaHeight, 100, KlineAndVolumSpace) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSForegroundColorAttributeName:self.dateColor,NSParagraphStyleAttributeName : self.alignmentCenter } context:nil];

                // draw date line
                UIBezierPath* dateLine = [UIBezierPath bezierPath];
                [dateLine moveToPoint:CGPointMake(x + self.KWidth / 2 + self.KWidth + self.KInterSpace , self.kLineAreaHeight)];
                [dateLine addLineToPoint:CGPointMake(x + self.KWidth / 2 + self.KWidth + self.KInterSpace, self.kLineAreaHeight - 5)];
                [self.chartFrameColor setStroke];
                dateLine.lineWidth = 0.5;
                [dateLine stroke];
            }
        }
        
        x -= self.KInterSpace + self.KWidth;
        recordIndex += 1;
    }

    [self drawFocuesdRecordInfo];
    [self drawMAInfo];

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


    self.backgroundColor = [UIColor whiteColor];

    self.axisMaxPrice = 0;
    self.axisMinPrice = 0;
    self.maxVolumn = 0;

    _KWidth = 10.0;
    _KInterSpace = 4.0;
    _lastVisibleKLineX = -5201314;
    _kLineType = TTKlineTypeDay;
    _showDate = YES;


    _chartFrameColor = [UIColor lightGrayColor];
    _referencePriceColor = [UIColor lightGrayColor];
    _referencePriceLineColor = [UIColor lightGrayColor];
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



}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}




@end
