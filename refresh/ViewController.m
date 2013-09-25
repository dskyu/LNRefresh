//
//  ViewController.m
//  refresh
//
//  Created by bunnydu on 13-9-25.
//  Copyright (c) 2013年 diditech. All rights reserved.
//

#import "ViewController.h"
#import "UIScrollView+LNRefresh.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *dataSource;

@end


@implementation ViewController

- (UITableView *)tableView
{
    if (!_tableView) {
        CGRect bounds = self.view.bounds;
        bounds.size.height -= 64;
        NSLog(@"%@",NSStringFromCGRect(bounds));
        _tableView = [[UITableView alloc] initWithFrame:bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setupDataSource];
    
    
    self.view.backgroundColor = [UIColor whiteColor];

    
    __weak typeof(self) weakSelf = self;
    
    [self.tableView addPullRefreshWithActionHandler:^{
        int64_t delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf.tableView beginUpdates];
            [weakSelf.dataSource insertObject:[NSDate date] atIndex:0];
            [weakSelf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
            [weakSelf.tableView endUpdates];
            
            [weakSelf.tableView.pullToRefreshView endRefresh];
        });
    }];
    
    [self.tableView addLoadMoreWithActionHandler:^{
        int64_t delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf.tableView beginUpdates];
            [weakSelf.dataSource addObject:[weakSelf.dataSource.lastObject dateByAddingTimeInterval:-90]];
            [weakSelf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:weakSelf.dataSource.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
            [weakSelf.tableView endUpdates];
            
            [weakSelf.tableView.loadMoreView endRefresh];
        });
    }];
}


- (void)viewDidAppear:(BOOL)animated {
    [self.tableView.pullToRefreshView triggerRefreshAnyWayWithControlHidden:NO];
}

#pragma mark - Actions
- (void)setupDataSource {
    self.dataSource = [NSMutableArray array];
    for(int i=0; i<10; i++)
        [self.dataSource addObject:[NSDate dateWithTimeIntervalSinceNow:-(i*90)]];
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    NSDate *date = [self.dataSource objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
    return cell;
}

@end
