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

@interface TTKLineChartViewController ()<TTStockSearchResultTVCDelegate,UISearchControllerDelegate,TTKLineChartDataSource>

@property (strong, nonatomic) StockCode* stock;

@property (strong, nonatomic) UISearchController* stockSearchController;

// Buttons for chaning K line type
@property (weak, nonatomic) IBOutlet UIButton *dayK;
@property (weak, nonatomic) IBOutlet UIButton *weekK;
@property (weak, nonatomic) IBOutlet UIButton *monthK;

@property (weak, nonatomic) IBOutlet TTTrainingKLineChart *kLineChart;

// provide k line data for training
@property (strong, nonatomic) TTKLineRecordsManager *recordManager;

@property(weak, nonatomic) UIActivityIndicatorView* fetchDateIndicator;

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

-(void)viewDidAppear:(BOOL)animated{
    
    self.fetchDateIndicator.bounds = CGRectMake(0, 0, 100, 100);
    self.fetchDateIndicator.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
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
-(UIActivityIndicatorView*)fetchDateIndicator{
    if (!_fetchDateIndicator) {
        UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.view addSubview:indicator];
        self.fetchDateIndicator = indicator;
        self.fetchDateIndicator.hidesWhenStopped = YES;
        self.fetchDateIndicator.hidden = YES;
        _fetchDateIndicator = indicator;
    }
    return _fetchDateIndicator;
}
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
    self.fetchDateIndicator.hidden = NO;
    [self.fetchDateIndicator startAnimating];

    self.recordManager.stockCode = stockCode;
    self.recordManager.kLineType = kLineType;
    [self.recordManager getRecordsFrom:from to:to completionHandler:^(NSArray *records, NSString *type) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.fetchDateIndicator stopAnimating];
            self.fetchDateIndicator.hidden = YES;
        });
        completionHander(records,type);
    }];

}

#pragma mark - navigation
-(void)tradeTraining:(UIBarButtonItem*) barButton{
    [self performSegueWithIdentifier:@"tradeTraining" sender:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
