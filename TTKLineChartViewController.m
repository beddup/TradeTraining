//
//  ViewController.m
//  TradeTraining
//
//  Created by Amay on 3/18/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTKLineChartViewController.h"
#import "AppDelegate.h"
#import "StockCode+CoreDataProperties.h"
#import "TTStockCodeHelper.h"
#import "NSDate+Extension.h"
#import "TTKLineChart.h"
#import "TTStockSearchResultTVC.h"
#import "TTTrainingKLineChart.h"
#import "TTKLineRecordsManager.h"

@interface TTKLineChartViewController ()<TTStockSearchResultTVCDelegate,UISearchControllerDelegate,TTKLineChartDataSource,UIPickerViewDataSource,UIPickerViewDelegate>

@property (strong, nonatomic) StockCode* stock;

@property (strong, nonatomic) UISearchController* stockSearchController;

// Buttons for chaning K line type
@property (weak, nonatomic) IBOutlet UIButton *dayK;
@property (weak, nonatomic) IBOutlet UIButton *weekK;
@property (weak, nonatomic) IBOutlet UIButton *monthK;

@property (weak, nonatomic) IBOutlet TTTrainingKLineChart *kLineChart;

// provide k line data for training
@property (strong, nonatomic) TTKLineRecordsManager *recordManager;

@property(nonatomic)float cash;
@property(nonatomic)NSInteger stockInHold;

@property(weak,nonatomic)UIView* tradeView;
@property(weak,nonatomic)UIPickerView* tradeNumberPicker;

@property (weak, nonatomic) UIActivityIndicatorView * indicator;

@end

@implementation TTKLineChartViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.kLineChart.dataSource = self;

    // default stock is 600000
    self.kLineChart.stockCode = @"600000.ss";
    self.title = @"浦发银行(600000)";

    [self setupSearchController];
    [self setupNavigationItem];
    [self highLightButton:self.dayK];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)setupNavigationItem{

    if (!self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchStock:)];

    }
    if (!self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"走势训练" style:UIBarButtonItemStylePlain target:self action:@selector(tradeTraining:)];
    }
    
}

-(void)setupSearchController{

    // very important, otherwise when searchResultTVC is presented, the serach bar will not be visible
    self.definesPresentationContext = YES;

    // Search Results Controller
    TTStockSearchResultTVC* searchResultTVC = [[TTStockSearchResultTVC alloc]initWithStyle:UITableViewStylePlain];
    searchResultTVC.delegate = self;

    self.stockSearchController = [[UISearchController alloc] initWithSearchResultsController:searchResultTVC];
    self.stockSearchController.delegate = self;
    self.stockSearchController.hidesNavigationBarDuringPresentation = NO;
    self.stockSearchController.dimsBackgroundDuringPresentation = YES;
    self.stockSearchController.searchResultsUpdater = searchResultTVC;
    self.stockSearchController.searchBar.placeholder = @"股票名称,代码或拼音简称";

}

#pragma mark - Properties
-(TTKLineRecordsManager*)recordManager{
    if (!_recordManager) {
        _recordManager = [[TTKLineRecordsManager alloc] init];
    }
    return _recordManager;
}

-(void)setStock:(StockCode *)stock{
    if (![_stock.code isEqualToString:stock.code]) {
        _stock = stock;

        //when stock is selected, updating k line chart and navigation bar
        self.kLineChart.stockCode = stock.completeCode;
        self.navigationItem.title = [NSString stringWithFormat:@"%@(%@)",stock.name,stock.code];
        self.navigationItem.titleView = nil;
    }
}

#pragma mark - Actions
- (void)searchStock:(id)sender {

    // update navigation bar and prepare to search stock
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;

    self.navigationItem.titleView = self.stockSearchController.searchBar;
    [self.stockSearchController.searchBar becomeFirstResponder];

}

- (IBAction)showDayKLine:(UIButton *)sender {
    [self highLightButton:sender];
    [self.kLineChart setKLineType:TTKlineTypeDay];
}


- (IBAction)showWeekKLine:(UIButton*)sender {

    [self highLightButton:sender];
    [self.kLineChart setKLineType:TTKlineTypeWeek];

}

- (IBAction)showMonthKLine:(UIButton*)sender {

    [self highLightButton:sender];
    [self.kLineChart setKLineType:TTKlineTypeMonth];
}

-(void)highLightButton:(UIButton*) button{

    self.weekK.backgroundColor = [UIColor whiteColor];
    self.dayK.backgroundColor = [UIColor whiteColor];
    self.monthK.backgroundColor = [UIColor whiteColor];

    button.layer.cornerRadius = 3.0;
    button.backgroundColor  = [UIColor orangeColor];
    
}


#pragma mark - TTStockSearchResultTVCDelegate 

-(void)didSelectStock:(StockCode *)stock{
    self.stock = stock;
    [self.stockSearchController dismissViewControllerAnimated:YES completion:nil];
    [self setupNavigationItem];
}

#pragma mark - UISearchControllerDelegate
- (void)willDismissSearchController:(UISearchController *)searchController{
    // when dismiss searchController, updating navifation bar
    self.navigationItem.titleView = nil;
    [self setupNavigationItem];
}

#pragma mark - TTKLineChartDataSource
-(void)getRecordsOfStock:(NSString *)stockCode From:(NSDate *)from to:(NSDate *)to kLineType:(NSString *)kLineType completionHander:(void (^)(NSArray *,NSString*))completionHander{

    self.recordManager.stockCode = stockCode;
    self.recordManager.kLineType = kLineType;
    [self.recordManager getRecordsFrom:from to:to completionHandler:completionHander];
}

#pragma mark - Trade Training

-(void)tradeTraining:(UIBarButtonItem*)sender{

    // set the initial cash
    self.cash = 100000.0;

    self.navigationItem.leftBarButtonItem.title = @"结束训练";
    self.navigationItem.title = [NSString stringWithFormat:@"现金%.0f万",self.cash / 10000];
    self.navigationItem.leftBarButtonItem.action = @selector(endTradeTraining:);
    [self.navigationController setToolbarHidden:NO animated:YES];

    // search should not work when training
    self.navigationItem.rightBarButtonItem.enabled = NO;

    // clear k line chart and prepare for training
    self.kLineChart.records  = nil;
    self.kLineChart.showDate = NO;
    [self hideLineTypeButton]; // only training day k line


    UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.bounds = CGRectMake(0, 0, 100, 100);
    [self.kLineChart addSubview:indicator];
    self.indicator = indicator;
    indicator.center = CGPointMake(CGRectGetMidX(self.kLineChart.bounds), CGRectGetMidY(self.kLineChart.bounds));
    [indicator startAnimating];

    // find a random stock , load the k line data and update k line chart
    StockCode* stock = [TTStockCodeHelper randomStock];
    self.recordManager.stockCode = stock.completeCode;
    self.recordManager.kLineType = TTKlineTypeDay;
    [self.recordManager getRecordsFrom:[NSDate distantPast] to:[NSDate date]  completionHandler:^(NSArray *records,NSString* type) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.indicator removeFromSuperview];
            self.indicator = nil;
            [self.kLineChart trainWithRecords:records];
        });
    }];


}
-(void)endTradeTraining:(UIBarButtonItem*) sender{

    self.navigationItem.leftBarButtonItem.title = @"走势训练";
    self.navigationItem.leftBarButtonItem.action = @selector(tradeTraining:);
    [self.navigationController setToolbarHidden:YES animated:YES];
    self.navigationItem.rightBarButtonItem.enabled = YES;

    [self showLineTypeButton];

    self.kLineChart.records = nil;
    self.kLineChart.showDate = YES;

    // reload the previous stock's k line chart
    if (self.stock) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@(%@)",self.stock.name,self.stock.code];
        self.kLineChart.stockCode = self.stock.completeCode;
    }else{
        self.kLineChart.stockCode = @"600000.ss";
        self.navigationItem.title = @"浦发银行(600000)";
    }

    // how is the profit
    float profit = self.cash  + self.stockInHold * [self.kLineChart currentTrainedRecord].closePrice - 100000;
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:nil message:[NSString stringWithFormat:@"收益%.2f; %.2f%%",profit,profit / 100000 * 100] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];

}

-(void)hideLineTypeButton{

    self.weekK.hidden = YES;
    self.dayK.hidden = YES;
    self.monthK.hidden = YES;

}

-(void)showLineTypeButton{
    self.weekK.hidden = NO;
    self.dayK.hidden = NO;
    self.monthK.hidden = NO;
    
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

@end
