//
//  TTStockSearchResultTVC.m
//  TradeTraining
//
//  Created by Amay on 3/31/16.
//  Copyright © 2016 Beddup. All rights reserved.
//

#import "TTStockSearchResultTVC.h"
#import "TTStockCodeHelper.h"
#import "StockCode+CoreDataProperties.h"


#pragma mark - TTStockSearchResultTVCCell
@interface TTStockSearchResultTVCCell : UITableViewCell

@property(strong,nonatomic)StockCode* stock;

@end

@implementation TTStockSearchResultTVCCell

-(void)setStock:(StockCode *)stock{
    _stock = stock;
    [self setNeedsDisplay];

}

-(void)drawRect:(CGRect)rect{

    NSMutableParagraphStyle* alignRight = [[NSMutableParagraphStyle alloc] init];
    alignRight.alignment = NSTextAlignmentRight;
    NSMutableParagraphStyle* alignCenter = [[NSMutableParagraphStyle alloc] init];
    alignCenter.alignment = NSTextAlignmentCenter;

    NSAttributedString* codeString =[[NSAttributedString alloc] initWithString:self.stock.code attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]}];
    [codeString drawAtPoint:CGPointMake(8, CGRectGetMidY(rect) - codeString.size.height / 2)];

    NSAttributedString* name =[[NSAttributedString alloc] initWithString:self.stock.name attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],NSParagraphStyleAttributeName:alignCenter}];
    [name drawInRect:CGRectMake(0, CGRectGetMidY(rect) - name.size.height / 2, CGRectGetWidth(rect), CGRectGetHeight(rect))];

    NSAttributedString* pinYin =[[NSAttributedString alloc] initWithString:self.stock.pinyin attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],NSParagraphStyleAttributeName:alignRight}];
    [pinYin drawInRect:CGRectMake(0, CGRectGetMidY(rect) - pinYin.size.height / 2,CGRectGetWidth(rect) - 8, CGRectGetHeight(rect))];

}
@end


@interface TTStockSearchResultTVC ()

@property(strong,nonatomic)NSArray* stocks;

@end

@implementation TTStockSearchResultTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[TTStockSearchResultTVCCell class] forCellReuseIdentifier:@"TTStockCell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.stocks.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TTStockSearchResultTVCCell *cell = (TTStockSearchResultTVCCell*)[tableView dequeueReusableCellWithIdentifier:@"TTStockCell" forIndexPath:indexPath];

    if (!cell) {
        cell = [[TTStockSearchResultTVCCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TTStockCell"];
    }
    cell.selectionStyle  = UITableViewCellSelectionStyleNone;
    cell.stock = self.stocks[indexPath.row];

    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 40.0;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{


    UIView* header = [[[NSBundle mainBundle] loadNibNamed:@"TTStockSearchResultTVCHeaderView" owner:nil options:nil] lastObject];
    return header;

}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    StockCode* stock = self.stocks[indexPath.row];
    [self.delegate didSelectStock:stock];
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController{

    // upate table view with search result
    NSString* keyword = searchController.searchBar.text;
   self.stocks = [TTStockCodeHelper searchStock:keyword];
    [self.tableView reloadData];
}

@end
