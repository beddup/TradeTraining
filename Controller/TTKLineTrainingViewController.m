//
//  TTKLineTrainingViewController.m
//  TradeTraining
//
//  Created by Amay on 4/8/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTKLineTrainingViewController.h"
#import "TTTrainingKLineChart.h"
#import "TTKLineRecordsManager.h"
#import "StockCode+CoreDataProperties.h"
#import "TTStockCodeHelper.h"
#import "NSDate+Extension.h"

@interface TTKLineTrainingViewController ()<TTKLineChartDataSource,UIPickerViewDataSource,UIPickerViewDelegate>

@property (strong, nonatomic) StockCode* stock;

@property (weak, nonatomic) IBOutlet TTTrainingKLineChart *kLineChart;

// provide k line data for training
@property (strong, nonatomic) TTKLineRecordsManager *recordManager;
@property (strong,nonatomic) NSDate* fromDate;
@property (strong,nonatomic) NSDate* toDate;


@property(nonatomic)float cash;
@property(nonatomic)NSInteger stockInHold;

@property(weak,nonatomic)UIView* tradeView;
@property(weak,nonatomic)UIPickerView* tradeNumberPicker;

@property(weak,nonatomic)UIActivityIndicatorView* fetchDateIndicator;


@end

@implementation TTKLineTrainingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(finishTraing:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"结束训练" style:UIBarButtonItemStylePlain target:self action:@selector(endTradeTraining:)];


    UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:indicator];
    self.fetchDateIndicator = indicator;

    self.navigationItem.leftBarButtonItem.enabled = NO;

    // prepare the k line chart, get random stock and download data
    [self prepareKLineChartForTraining];

}
-(void)viewDidAppear:(BOOL)animated{
    
    self.fetchDateIndicator.bounds = CGRectMake(0, 0, 100, 100);
    self.fetchDateIndicator.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
}

#pragma mark - Properties
-(TTKLineRecordsManager*)recordManager{
    if (!_recordManager) {
        _recordManager = [[TTKLineRecordsManager alloc] init];
    }
    return _recordManager;
}


#pragma mark - Trade Training
-(void)finishTraing:(id)sender{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
-(void)prepareKLineChartForTraining{

    self.kLineChart.records = nil;
    self.cash = 100000.0;
    self.stockInHold = 0;

    self.navigationItem.title = [NSString stringWithFormat:@"现金%.0f万",self.cash / 10000];

    self.kLineChart.dataSource = self;
    // clear k line chart and prepare for training
    self.kLineChart.showDate = NO;
    // find a random stock , load the k line data and update k line chart
    StockCode* stock = [TTStockCodeHelper randomStock];
    self.stock = stock;

    [self.fetchDateIndicator startAnimating];

    self.recordManager.stockCode = stock.completeCode;
    self.recordManager.kLineType = TTKlineTypeDay;
    // train with 2 year period of the past 10 years data
    self.fromDate = [[NSDate date] offsetYears:-2 - arc4random() % 8];
    self.toDate = [self.fromDate offsetYears:2];
    [self.recordManager getRecordsFrom:self.fromDate to:self.toDate  completionHandler:^(NSArray *records,NSString* type) {
        if (records.count <= 0) {
            [self prepareKLineChartForTraining];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{

                [self.fetchDateIndicator stopAnimating];
                self.fetchDateIndicator.hidden = YES;
                self.navigationItem.leftBarButtonItem.enabled = YES;

                [self.navigationController setToolbarHidden:NO animated:NO];
                [self.kLineChart setNeedsLayout];
                [self.kLineChart trainWithRecords:records];
        });
        }
    }];

}
-(void)endTradeTraining:(UIBarButtonItem*) sender{

    [self.navigationController setToolbarHidden:YES animated:YES];

    // how is the profit
    float profit = self.cash  + self.stockInHold * [self.kLineChart currentTrainedRecord].closePrice - 100000;

    NSString* alertTitle = [NSString stringWithFormat:@"收益%.2f元(%.2f%%)",profit,profit / 100000 * 100];
    NSString* alertMessage = [NSString stringWithFormat:@"训练股票：%@(%@)\n时间：%@ - %@",self.stock.name,self.stock.code, [self.fromDate stringWithFormat:@"yyyy-MM-dd"],[self.toDate stringWithFormat:@"yyyy-MM-dd"]];

    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:alertTitle message:alertMessage delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];

    self.navigationItem.leftBarButtonItem.title = @"再来一次";
    self.navigationItem.leftBarButtonItem.action = @selector(trainAgain:);

    self.kLineChart.records = nil;

}

-(void)trainAgain:(id)sender{
    [self prepareKLineChartForTraining];

    self.navigationItem.leftBarButtonItem.title = @"结束训练";
    self.navigationItem.leftBarButtonItem.action = @selector(endTradeTraining:);
    self.navigationItem.leftBarButtonItem.enabled = NO;

}

- (IBAction)buy:(id)sender {

    if (self.cash / [self.kLineChart currentTrainedRecord].closePrice >= 100) {
        [self showTradeView:YES];
    }else{
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:nil message:@"现金不足" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
        [alert show];
    }

}

- (IBAction)sell:(id)sender {

    if (self.stockInHold > 0) {
        [self showTradeView:NO];
    }else{
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:nil message:@"无持仓" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
        [alert show];

    }
}

- (IBAction)showNextRecord:(id)sender {

    [self.kLineChart showNextRecord];
    float capital  = self.cash + self.stockInHold * [self.kLineChart currentTrainedRecord].closePrice;
    float ratio = self.stockInHold * [self.kLineChart currentTrainedRecord].closePrice / capital;
    self.navigationItem.title = [NSString stringWithFormat:@"资产%.2f万,持仓%.1f%%",capital / 10000, ratio * 100];
}


static NSInteger BuyIdentifier = 105;
static NSInteger SellIdentifier = 925;

-(void)showTradeView:(BOOL)buy{

    self.navigationController.toolbarHidden  = YES;

    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - 200, CGRectGetWidth(self.view.bounds), 200)];
    self.tradeView = view;
    view.layer.shadowOffset = CGSizeMake(0, 3);
    view.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    view.backgroundColor = [UIColor whiteColor];
    // use tag to tell whether
    view.tag = buy? BuyIdentifier : SellIdentifier;

    UIPickerView* pickerView = [[UIPickerView alloc]initWithFrame:view.bounds];
    [view addSubview:pickerView];
    pickerView.dataSource = self;
    pickerView.delegate = self;
    pickerView.showsSelectionIndicator = YES;
    self.tradeNumberPicker = pickerView;

    UIButton* ok = [UIButton buttonWithType:UIButtonTypeSystem];
    ok.frame = CGRectMake(8, 8, 50, 44);
    [ok setTitle:@"确定" forState:UIControlStateNormal];
    [ok addTarget:self action:@selector(tradeConfirmed:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:ok];

    UIButton* cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    cancel.frame = CGRectMake(CGRectGetMaxX(view.bounds) - 8 - 50, 8, 50, 44);
    [cancel setTitle:@"取消" forState:UIControlStateNormal];
    [cancel addTarget:self action:@selector(tradeCancel:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:cancel];

    [self.view addSubview:view];

}

-(void)tradeConfirmed:(UIButton*)button{
    if (self.tradeView.tag == BuyIdentifier) {
        //buy confirmed
        NSInteger number = ([self.tradeNumberPicker selectedRowInComponent:1] + 1) * 100;
        self.stockInHold += number;
        self.cash -= number * [self.kLineChart currentTrainedRecord].closePrice;
    }else{
        //sell confirmed
        NSInteger number = ([self.tradeNumberPicker selectedRowInComponent:1] + 1) * 100;
        self.stockInHold -= number;
        self.cash += number * [self.kLineChart currentTrainedRecord].closePrice;
    }

    float capital  = self.cash + self.stockInHold * [self.kLineChart currentTrainedRecord].closePrice;
    float ratio = self.stockInHold * [self.kLineChart currentTrainedRecord].closePrice / capital;
    self.navigationItem.title = [NSString stringWithFormat:@"资产%.2f万,持仓%.1f%%",capital / 10000, ratio * 100];

    [self.tradeView removeFromSuperview];
    self.tradeView = nil;
    self.tradeNumberPicker = nil;

    self.navigationController.toolbarHidden = NO;

}

-(void)tradeCancel:(UIButton*)button{

    self.navigationController.toolbarHidden = NO;
    [self.tradeView removeFromSuperview];
    self.tradeView = nil;
    self.tradeNumberPicker = nil;

}
#pragma mark - TTKLineChartDataSource
-(void)getRecordsOfStock:(NSString *)stockCode From:(NSDate *)from to:(NSDate *)to kLineType:(NSString *)kLineType completionHander:(void (^)(NSArray *,NSString*))completionHander{

    self.fetchDateIndicator.hidden = NO;
    [self.fetchDateIndicator startAnimating];

    self.recordManager.stockCode = stockCode;
    self.recordManager.kLineType = kLineType;
    [self.recordManager getRecordsFrom:from to:to completionHandler:^(NSArray *records, NSString *type) {
        [self.fetchDateIndicator stopAnimating];
        completionHander(records,type);
    }];
    
}

#pragma mark - UIPickerView DataSource and delegate
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 3;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if (component == 0 || component == 2) {
        return 1;
    }
    NSInteger maxNumber = 0;
    if (self.tradeView.tag == BuyIdentifier) {
        maxNumber = (NSInteger)(self.cash / [self.kLineChart currentTrainedRecord].closePrice / 100);
    }else if(self.tradeView.tag == SellIdentifier){
        maxNumber = self.stockInHold / 100;
    }
    return maxNumber;

}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{

    if (component == 0) {
        return self.tradeView.tag == BuyIdentifier ? @"买入" : @"卖出";
    }else if (component == 1){
        return [NSString stringWithFormat:@"%d",row + 1];
    }else{
        return @"手";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
