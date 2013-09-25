//
//  UIScrollView+LNRefresh.m
//  lovenote
//
//  created by Dskyu  on 13-05-07.
//  Copyright (c) 2013年 Lovenote . All rights reserved.
//

#import "UIScrollView+LNRefresh.h"
#import <objc/runtime.h>

static float kRefreshHeight = 44;

@interface LNRefresh()

@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, copy) void (^actionHandler)(void);

- (id)initWithScrollView:(UIScrollView *)scrollView style:(RefreshViewType)type actionHandler:(void (^)(void))actionHandler;
@end

@implementation LNRefresh
- (id)initWithScrollView:(UIScrollView *)scrollView style:(RefreshViewType)type actionHandler:(void (^)(void))actionHandler;
{
    _scrollView = scrollView;
    _actionHandler = actionHandler;
    _viewType = type;
    _isRefreshing = NO;
    _reachToEnd = NO;
    _refreshState = RefreshControlStateNormal;
    

    if (_viewType == RefreshViewTypePull) {
        self = [super initWithFrame:CGRectMake(0, -kRefreshHeight, scrollView.frame.size.width, kRefreshHeight)];
        _refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, kRefreshHeight)];
        _refreshLabel.text = NSLocalizedString(@"下拉刷新",nil);
        
    }else if (_viewType == RefreshViewTypeLoadMore){
        self = [super initWithFrame:CGRectMake(0, scrollView.frame.size.height, scrollView.frame.size.width, kRefreshHeight)];
        _refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, kRefreshHeight)];
        _refreshLabel.text = NSLocalizedString(@"加载更多",nil);
        
    }
    

    _refreshLabel.backgroundColor = [UIColor clearColor];
    _refreshLabel.font  = [UIFont systemFontOfSize:14];
    _refreshLabel.textColor = [UIColor grayColor];
    _refreshLabel.textAlignment = NSTextAlignmentCenter; 
    _refreshLabel.shadowColor = [UIColor whiteColor];
    _refreshLabel.shadowOffset = CGSizeMake(0, 1);
    
    _refreshIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _refreshIndicator.hidden = YES;
    _refreshIndicator.center = _refreshLabel.center;
    
    [self addSubview:_refreshLabel];
    [self addSubview:_refreshIndicator];
    [scrollView addSubview:self];
    return self;
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.viewType == RefreshViewTypePull) {
        if (_refreshState==RefreshControlStateOverflow) {
            _refreshState = RefreshControlStateLoading;
            _refreshIndicator.hidden = NO;
            _refreshLabel.hidden = YES;
            [_refreshIndicator startAnimating];
            [UIView animateWithDuration:0.5 animations:^{
                self.scrollView.contentInset = UIEdgeInsetsMake(kRefreshHeight, 0, 0, 0);
            }];
            _refreshLabel.text = NSLocalizedString(@"下拉刷新",nil);
        }
    }else if (self.viewType == RefreshViewTypeLoadMore){
        if (_refreshState==RefreshControlStateOverflow) {
            _refreshState = RefreshControlStateLoading;
            _refreshIndicator.hidden = NO;
            _refreshLabel.hidden = YES;
            [_refreshIndicator startAnimating];
            [UIView animateWithDuration:0.5 animations:^{
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, kRefreshHeight, 0);
            }];
            _refreshLabel.text = NSLocalizedString(@"加载更多",nil);
        }
    }
    
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (self.viewType == RefreshViewTypePull) {
        if (self.scrollView.contentOffset.y<=-kRefreshHeight) {
            if (_refreshState==RefreshControlStateNormal) {
                _refreshLabel.text = NSLocalizedString(@"释放刷新",nil);
                _refreshState = RefreshControlStateOverflow;
            }
        } else if (_refreshState==RefreshControlStateOverflow) {
            _refreshLabel.text = NSLocalizedString(@"下拉刷新",nil);
            _refreshState = RefreshControlStateNormal;
        }
    }else if (self.viewType == RefreshViewTypeLoadMore && self.reachToEnd == NO){
        NSInteger height = self.scrollView.contentSize.height<self.scrollView.frame.size.height?self.scrollView.frame.size.height:self.scrollView.contentSize.height;
        if (self.scrollView.contentOffset.y>=kRefreshHeight+height-self.scrollView.frame.size.height) {
            if (_refreshState==RefreshControlStateNormal) {
                _refreshLabel.text = NSLocalizedString(@"释放刷新",nil);
                _refreshState = RefreshControlStateOverflow;
            }
        } else if (_refreshState==RefreshControlStateOverflow) {
            _refreshLabel.text = NSLocalizedString(@"加载更多",nil);
            _refreshState = RefreshControlStateNormal;
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (_refreshState==RefreshControlStateLoading && !_isRefreshing) {
        
        _isRefreshing = YES;
        if (_actionHandler) {
            _actionHandler();
        }
    }
}
- (void)triggerRefreshAnyWayWithControlHidden:(BOOL)hidden
{
    if (_viewType == RefreshViewTypeLoadMore) {
        return;
    }
    
    if (_refreshState == RefreshControlStateLoading) {
        return;
    }
    _refreshState=RefreshControlStateLoading;
    _isRefreshing = YES;
    _refreshIndicator.hidden = NO;
    _refreshLabel.hidden = YES;
    _refreshLabel.text = NSLocalizedString(@"下拉刷新",nil);
    [_refreshIndicator startAnimating];
    if (hidden) {
        [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
    } else {
        self.scrollView.contentInset = UIEdgeInsetsMake(kRefreshHeight, 0, 0, 0);
        [self.scrollView setContentOffset:CGPointMake(0, -kRefreshHeight) animated:YES];
    }
    if (_actionHandler) {
        _actionHandler();
    }
}
- (void)endRefresh
{
    [self endRefreshWithInfo:nil delay:0];
}

- (void)endRefreshWithInfo:(NSString *)info
{
    [self endRefreshWithInfo:info delay:0];
}

- (void)endRefreshWithDelay:(CGFloat)delay
{
    [self endRefreshWithInfo:nil delay:delay];
}
- (void)endRefreshWithInfo:(NSString *)info delay:(CGFloat)delay
{
    _refreshLabel.hidden = NO;
    _refreshIndicator.hidden = YES;
      
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        _isRefreshing = NO;

        [UIView animateWithDuration:0.25 animations:^{
            if (self.viewType == RefreshViewTypePull) {
                self.scrollView.contentOffset = CGPointZero;
            }else if (self.viewType == RefreshViewTypeLoadMore){
                self.scrollView.contentOffset = CGPointMake(0, self.scrollView.contentOffset.y + 1);  //add 1px for showing
            }
        } completion:^(BOOL finished) {
            if (self.viewType == RefreshViewTypePull) {
                _refreshLabel.text = NSLocalizedString(@"下拉刷新",nil);
            }else if (self.viewType == RefreshViewTypeLoadMore){
                _refreshLabel.text = NSLocalizedString(@"加载更多",nil);
            }
            if (info) {
                _refreshLabel.text = info;
            }
            
            [UIView animateWithDuration:0.25 animations:^{
                self.scrollView.contentInset = UIEdgeInsetsZero;
            } completion:^(BOOL finished) {
                self.scrollView.contentInset = UIEdgeInsetsZero;
            }];

            _refreshState = RefreshControlStateNormal;
        }];
    });
    return;
}
@end



static char UIScrollViewPullToRefreshView;
static char UIScrollViewLoadMoreView;

@implementation UIScrollView (LNRefreshView)

@dynamic pullToRefreshView;
@dynamic loadMoreView;

- (void)addPullRefreshWithActionHandler:(void (^)(void))actionHandler
{
    LNRefresh *pullRefreshView = [[LNRefresh alloc] initWithScrollView:self style:RefreshViewTypePull actionHandler:actionHandler];
    self.pullToRefreshView = pullRefreshView;
    [self setDelegate:self];
}

- (void)setPullToRefreshView:(LNRefresh *)pullToRefreshView
{
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
}
- (LNRefresh *)pullToRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)addLoadMoreWithActionHandler:(void (^)(void))actionHandler
{
    LNRefresh *loadMoreView = [[LNRefresh alloc] initWithScrollView:self style:RefreshViewTypeLoadMore actionHandler:actionHandler];
    self.loadMoreView = loadMoreView;
    [self addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self setDelegate:self];
}

- (void)setLoadMoreView:(LNRefresh *)loadMoreView
{
    objc_setAssociatedObject(self, &UIScrollViewLoadMoreView,
                             loadMoreView,
                             OBJC_ASSOCIATION_ASSIGN);
}
- (LNRefresh *)loadMoreView {
    return objc_getAssociatedObject(self, &UIScrollViewLoadMoreView);
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect frame = self.loadMoreView.frame;
        CGSize contentSize = self.contentSize;
        frame.origin.y = contentSize.height < self.frame.size.height ? self.frame.size.height : contentSize.height;
        self.loadMoreView.frame = frame;
 
    });
}

- (void)remove
{
    [self removeObserver:self forKeyPath:@"contentSize"];
}

#pragma mark UIScrollerViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [scrollView.pullToRefreshView scrollViewDidEndDecelerating:scrollView];
    [scrollView.loadMoreView scrollViewDidEndDecelerating:scrollView];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [scrollView.pullToRefreshView scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    [scrollView.loadMoreView scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [scrollView.pullToRefreshView scrollViewDidScroll:scrollView];
    [scrollView.loadMoreView scrollViewDidScroll:scrollView];
}
@end

