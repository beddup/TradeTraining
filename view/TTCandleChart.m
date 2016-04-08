//
//  TTKLineChart.m
//  TradeTraining
//
//  Created by Amay on 3/21/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTCandleChart.h"
#import "TTKLineRecordsManager.h"
#import "NSDate+Extension.h"
#import "TTDefines.h"
#import "TTRecordInfoView.h"

@interface TTCandleChart()

// value for drawing
@property(nonatomic) CGFloat axisMaxPrice;
@property(nonatomic) CGFloat axisMinPrice;
@property(nonatomic) NSInteger maxVolumn;

@property(nonatomic) CGFloat kLineAreaHeight;
@property(nonatomic) CGFloat heightAndPriceAspect;
@property(nonatomic) CGFloat maxVolumHegiht;
@property(nonatomic) CGFloat KWidth; // width of k line
@property(nonatomic) CGFloat KInterSpace; // space between two k line

// the position X of the last visible k line in the chart
@property(nonatomic) CGFloat lastVisibleKLineX;
// the index of the last visible k line record
@property(nonatomic) NSInteger lastVisibleRecordIndex;

// coclor for drawing
@property(strong,nonatomic) UIColor* klineIncreaseColor;
@property(strong,nonatomic) UIColor* klineDecreaseColor;
@property(strong,nonatomic) UIColor* klineNotChangeColor;
@property(strong,nonatomic) UIColor* focusedCrossLineColor;
@property(strong,nonatomic) UIColor* dateColor;

// paragraph stye
@property(strong,nonatomic)NSMutableParagraphStyle* alignmentCenter;
@property(strong,nonatomic)NSMutableParagraphStyle* alignmentRight;

// the record index where long pressed happened;
@property(nonatomic) NSInteger focusedRecordIndex;
@property(strong, nonatomic) UILongPressGestureRecognizer* longPressGesture;

// ma line
@property(strong,nonatomic)UIBezierPath* ma5;
@property(strong,nonatomic)UIBezierPath* ma10;
@property(strong,nonatomic)UIBezierPath* ma20;

@property(weak,nonatomic)UIView* bkgView; // use a background view to display the already drawed klines, so that only part of contents would be drawn
@property(nonatomic)BOOL needResetBkgView; // indicate whether the bkgview's contents should be redrawn

@property(nonatomic)BOOL needResetDirtyRect;
@property(nonatomic)CGRect dirtyRect; // dirtyRect indicate which part of the view should be redrawn

@property(nonatomic)BOOL isFetchingData;

@end


@implementation TTCandleChart

#pragma mark - Properties

-(void)setLastVisibleKLineX:(CGFloat)lastVisibleKLineX{

    if (_lastVisibleKLineX != lastVisibleKLineX) {
        _lastVisibleKLineX = lastVisibleKLineX;
        [self calculateMaxPriceAndMaxVolumn];
        if (self.records.count) {
            self.needResetBkgView ? [self setNeedsDisplay]:[self setNeedsDisplayInRect:self.dirtyRect];
        }
    }
}


-(void)setRecords:(NSArray *)records{

    _records = records;

    self.needResetBkgView = YES;
    self.isFetchingData = NO;

    [self calculateMaxPriceAndMaxVolumn];

    if (self.records.count <= 0 ) {
        self.lastVisibleKLineX = CGRectGetWidth(self.bounds) * 2 / 3;
        self.lastVisibleRecordIndex = 0;
    }

    [self setNeedsDisplay];

}

-(void)setNeedResetBkgView:(BOOL)needResetBkgView{
    _needResetBkgView = needResetBkgView;

    if (needResetBkgView) {
        // when set need reset, the bkgview will be redraw in the next pan gesture cycle
        self.bkgView.layer.contents = nil;
        self.bkgView.hidden = YES;
        self.needResetDirtyRect = YES;
        self.dirtyRect = self.bounds;
    }
}

#pragma mark - CalcutionForDrawing
-(void)calculateMaxPriceAndMaxVolumn{

    [self.ma5 removeAllPoints];
    [self.ma10 removeAllPoints];
    [self.ma20 removeAllPoints];

    if(!self.records.count) {

        return;
    }


    NSInteger recordIndex = self.lastVisibleRecordIndex;
    CGFloat x = self.lastVisibleKLineX;

    // calculate the axisMaxPrice and axisMinPrice and maxVolumn, according to current visible records
    CGFloat maxPrice = 0;
    CGFloat minPrice = [(TTKLineRecord*)self.records[0] minPrice];
    CGFloat maxVolumn = 0;
    while ( x > - self.KWidth  ) {

        TTKLineRecord * record = self.records[recordIndex];
        if (record.maxPrice > maxPrice) {
            maxPrice = record.maxPrice;
        }
        if (record.minPrice < minPrice) {
            minPrice = record.minPrice;
        }
        if (record.volumn > maxVolumn) {
            maxVolumn = record.volumn;
        }

        x -= self.KInterSpace + self.KWidth;
        recordIndex += 1;
        if (recordIndex >= self.records.count) {
            if (![self.kLineType isEqualToString:TTKlineTypeMonth] && !self.isFetchingData){
                self.isFetchingData = YES;
                [self.delegate feedMoreDateCompletionHandler:^{
                    self.isFetchingData = NO;
                }];
            }
            break;
        }
    }

    if (self.axisMaxPrice < maxPrice || self.axisMaxPrice > maxPrice * 1.2) {
        self.axisMaxPrice = maxPrice * 1.1;
        [self.delegate pricenRangeChangedWithMaxPrice:self.axisMaxPrice minPrice:self.axisMinPrice];
        self.needResetBkgView = YES;
    }
    if (self.axisMinPrice > minPrice || self.axisMinPrice < minPrice * 0.8) {
        self.axisMinPrice = minPrice * 0.9;
        [self.delegate pricenRangeChangedWithMaxPrice:self.axisMaxPrice minPrice:self.axisMinPrice];
        self.needResetBkgView = YES;
    }
    if (self.maxVolumn < maxVolumn || self.maxVolumn > maxVolumn * 1.3) {
        self.maxVolumn = maxVolumn * 1.1 ;
        self.needResetBkgView = YES;
    }

    self.heightAndPriceAspect = self.kLineAreaHeight / (self.axisMaxPrice - self.axisMinPrice);

    // create ma line here instead of in drawRect to try to save some time
    recordIndex =self.lastVisibleRecordIndex > 0 ? self.lastVisibleRecordIndex - 1 : self.lastVisibleRecordIndex;
    x = self.lastVisibleRecordIndex > 0 ? self.lastVisibleKLineX + self.KWidth + self.KInterSpace : self.lastVisibleKLineX;
    TTKLineRecord* record = self.records[recordIndex];

    [self.ma5 moveToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA5) * self.heightAndPriceAspect)];
    [self.ma10 moveToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA10) * self.heightAndPriceAspect)];
    [self.ma20 moveToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA20) * self.heightAndPriceAspect)];

    while ( x > - self.KWidth - self.KWidth - self.KInterSpace ) {
        if (recordIndex >= self.records.count) {
            break;
        }
        TTKLineRecord * record = self.records[recordIndex];

        if (record.MA5 > 0) {
            [self.ma5 addLineToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA5) * self.heightAndPriceAspect)];
        }
        if (record.MA10 > 0) {
            [self.ma10 addLineToPoint:CGPointMake(x + self.KWidth / 2, (self.axisMaxPrice - record.MA10) * self.heightAndPriceAspect)];
        }
        if (record.MA20 > 0) {
            [self.ma20 addLineToPoint:CGPointMake(x +self.KWidth / 2, (self.axisMaxPrice - record.MA20) * self.heightAndPriceAspect)];
        }

        x -= self.KInterSpace + self.KWidth;
        recordIndex += 1;
    }

}
#pragma mark - Draw
-(void)drawMALine{

    // draw ma line
    [MA5Color setStroke];
    [self.ma5 stroke];
    [MA10Color setStroke];
    [self.ma10 stroke];
    [MA20Color setStroke];
    [self.ma20 stroke];

}

-(void)drawFrameAndReferenceLine{

    [[UIColor lightGrayColor]setStroke];

    UIBezierPath* frameLinePath = [UIBezierPath bezierPath];
    [frameLinePath moveToPoint:CGPointMake(0, 0)];
    [frameLinePath addLineToPoint:CGPointMake(CGRectGetMaxX(self.bounds), 0)];
    [frameLinePath moveToPoint:CGPointMake(0, self.kLineAreaHeight)];
    [frameLinePath addLineToPoint:CGPointMake(CGRectGetMaxX(self.bounds), self.kLineAreaHeight)];
    [frameLinePath moveToPoint:CGPointMake(0, self.kLineAreaHeight + KlineAndVolumSpace)];
    [frameLinePath addLineToPoint:CGPointMake(CGRectGetMaxX(self.bounds), self.kLineAreaHeight + KlineAndVolumSpace)];
    frameLinePath.lineWidth = 0.5;
    [frameLinePath stroke];

    UIBezierPath* referenceLine = [UIBezierPath bezierPath];
    for (NSInteger index = 1; index < AxisPriceZoneCount; index++) {
        [referenceLine moveToPoint:CGPointMake(0, self.kLineAreaHeight / AxisPriceZoneCount * index)];
        [referenceLine addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds), self.kLineAreaHeight / AxisPriceZoneCount * index)];
    }
    CGFloat dashPattern[] = {5.0,3.0};
    [referenceLine setLineDash:dashPattern count:2 phase:1];
    referenceLine.lineWidth = 0.5;
    [referenceLine stroke];
}


- (void)drawRect:(CGRect)rect {

    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    [self drawFrameAndReferenceLine];
    [self drawMALine];

    // draw K line and volumn
    CGFloat x = self.lastVisibleKLineX;
    NSInteger recordIndex = self.lastVisibleRecordIndex;

    UIBezierPath* dateLine = [UIBezierPath bezierPath];
    while (x > -self.KWidth + CGRectGetMinX(self.dirtyRect)) {
        // only need to draw the dirty rect to save some time
        if (x > CGRectGetMaxX(self.dirtyRect)) {
            x -= self.KInterSpace + self.KWidth;
            recordIndex += 1;
            continue;
        }

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
        UIBezierPath* volumnPath = [UIBezierPath bezierPathWithRect:CGRectMake(x, CGRectGetMaxY(self.bounds) - volumnHeight, self.KWidth, volumnHeight)];
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

        // draw focused cross line
        if (self.focusedRecordIndex == recordIndex){
            UIBezierPath* crossLine = [UIBezierPath bezierPath];
            [crossLine moveToPoint:CGPointMake(x + self.KWidth / 2, 0)];
            [crossLine addLineToPoint:CGPointMake(x + self.KWidth / 2, self.kLineAreaHeight)];
            [crossLine moveToPoint:CGPointMake(0, closeY)];
            [crossLine addLineToPoint:CGPointMake(CGRectGetMaxX(self.bounds), closeY)];
            [[UIColor lightGrayColor] setStroke];
            [crossLine stroke];
        }

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
                [dateLine moveToPoint:CGPointMake(x + self.KWidth / 2 + self.KWidth + self.KInterSpace , self.kLineAreaHeight)];
                [dateLine addLineToPoint:CGPointMake(x + self.KWidth / 2 + self.KWidth + self.KInterSpace, self.kLineAreaHeight - 5)];
            }
        }

        x -= self.KInterSpace + self.KWidth;
        recordIndex += 1;
    }

    [[UIColor lightGrayColor] setStroke];
    [dateLine stroke];

    NSLog(@" draw time :%.2fms",(CFAbsoluteTimeGetCurrent() - startTime) * 1000);
}


#pragma mark - Gestures;
-(void)pinch:(UIPinchGestureRecognizer* )pinchGesture{

    if (!self.records.count) {
        return;
    }

    if (pinchGesture.state == UIGestureRecognizerStateBegan) {
        self.needResetBkgView = YES;
    }else if (pinchGesture.state == UIGestureRecognizerStateChanged){
        CGFloat scale = pinchGesture.scale;
        if ((self.KWidth > 30 && scale > 1.0) || (self.KWidth < 5 && scale < 1.0)) {
            return;
        }

        self.KWidth *= scale;
        self.KInterSpace *= scale;

        CGFloat x = CGRectGetMidX(self.bounds) +  (self.lastVisibleKLineX -  CGRectGetWidth(self.bounds) / 2) * scale;

        [self adjustLastVisibleKlineX:x];

        pinchGesture.scale = 1.0;

    }else if (pinchGesture.state == UIGestureRecognizerStateEnded) {
        [self resetBKGView];
    }
}

-(void)pan:(UIPanGestureRecognizer*)panGesture{

    if (!self.records.count) {
        return;
    }

    if (self.needResetBkgView) {
        [self resetBKGView];
    }

    if (panGesture.state == UIGestureRecognizerStateChanged) {

        CGFloat translationX = [panGesture translationInView:self].x;

        // move the backgourndview and adjust the dirty rect, so that the background view and the updated k line redrawn in dirty rect can make the correct chart together
        self.bkgView.center = CGPointMake(translationX + self.bkgView.center.x, self.bkgView.center.y);
        [self updateDirtyRectForTranslation:translationX];

        CGFloat x = self.lastVisibleKLineX + translationX;
        [self adjustLastVisibleKlineX:x];
        [panGesture setTranslation:CGPointZero inView:self];

    }else if (panGesture.state  == UIGestureRecognizerStateEnded ||
              panGesture.state == UIGestureRecognizerStateCancelled){

        [self resetBKGView];
    }

}


-(void)longPress:(UILongPressGestureRecognizer*)longPress{

    if (!self.records.count) {
        return;
    }
    CGFloat locationX = [longPress locationInView:self].x;

    if (longPress.state  == UIGestureRecognizerStateBegan ||
        longPress.state  == UIGestureRecognizerStateChanged) {
        self.bkgView.hidden = YES;
        if (locationX >= self.lastVisibleKLineX) {
            self.focusedRecordIndex = self.lastVisibleRecordIndex;
        }else{
            NSInteger offset =(NSInteger)((self.lastVisibleKLineX + self.KWidth / 2 - locationX) / (self.KWidth + self.KInterSpace) + 0.5);
            self.focusedRecordIndex = self.lastVisibleRecordIndex  + offset;
        }

    }else{
        if (self.bkgView.layer.contents) {
            self.bkgView.hidden = NO;
        }
        self.focusedRecordIndex = -1;
    }

    [self.delegate focusedRecord:self.focusedRecordIndex >= 0 ? self.records[self.focusedRecordIndex] : nil inRightHalfArea:locationX > CGRectGetMidX(self.bounds)];

    // because the cross line must be redrawn, so dirtyRect will the whole bounds
    self.dirtyRect = self.bounds;
    [self setNeedsDisplay];
    
}


-(void)updateDirtyRectForTranslation:(float)x{

    if (self.needResetDirtyRect) {
        self.dirtyRect = CGRectMake(x > 0.0 ? 0.0 : CGRectGetMaxX(self.bounds) + x, 0.0, x, CGRectGetHeight(self.bounds));
        self.needResetDirtyRect = NO;
        return;
    }

    if (self.dirtyRect.origin.x > 0.0 && self.dirtyRect.origin.x < CGRectGetMaxX(self.bounds)) {
        self.dirtyRect = CGRectMake(self.dirtyRect.origin.x + x, 0,CGRectGetWidth(self.bounds)- x - self.dirtyRect.origin.x, self.dirtyRect.size.height);
    }else if(self.dirtyRect.origin.x == 0.0){
        self.dirtyRect = CGRectMake(0, 0, self.dirtyRect.size.width + x, self.dirtyRect.size.height);
    }else{
        self.needResetBkgView = YES;
    }
}

-(void)resetBKGView{

    // get the image of current chart, and set it to background view
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawLayer:self.layer inContext:context];
    [[UIImage imageWithCGImage:(__bridge CGImageRef _Nonnull)(self.bkgView.layer.contents)] drawInRect:self.bkgView.frame];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.bkgView.frame = self.bounds;
    self.bkgView.layer.contents = (__bridge id _Nullable)(image.CGImage);
    self.bkgView.hidden = NO;

    self.needResetBkgView = NO;
    self.needResetDirtyRect = YES;
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


#pragma  mark - setup

-(void)layoutSubviews{

    self.kLineAreaHeight = CGRectGetHeight(self.bounds) * KlineAreaHeightRatio;
    self.maxVolumHegiht = CGRectGetHeight(self.bounds) * (1 - KlineAreaHeightRatio) - KlineAndVolumSpace;

    if (self.lastVisibleKLineX == -5201314 ) {
        // initail position
        _lastVisibleKLineX = CGRectGetWidth(self.bounds) * 2 / 3;
    }else{
        self.lastVisibleKLineX = CGRectGetMaxX(self.bounds) - self.KWidth - self.KInterSpace;
    }

    self.dirtyRect = self.bounds;

    self.bkgView.frame = self.bounds;
}

-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    self.opaque = YES;
    self.backgroundColor = [UIColor whiteColor];
    self.clipsToBounds = YES;

    self.axisMaxPrice = 0;
    self.axisMinPrice = 10000.0;
    self.maxVolumn = 0;

    self.focusedRecordIndex = -1;
    
    _KWidth = 10.0;
    _KInterSpace = 4.0;
    _lastVisibleKLineX = -5201314;
    _kLineType = TTKlineTypeDay;
    _showDate = YES;

    _klineIncreaseColor = [UIColor redColor];
    _klineDecreaseColor = [UIColor greenColor];
    _klineNotChangeColor = [UIColor blackColor];
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

    // background view
    UIView* bkg = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:bkg];
    bkg.backgroundColor = [UIColor whiteColor];
    self.bkgView = bkg;
    self.bkgView.hidden = YES;

    self.dirtyRect = self.bounds;

}
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}




@end
