//
//  UIScrollView+LNRefresh.m
//  lovenote
//
//  created by Dskyu  on 13-05-07.
//  Copyright (c) 2013年 Lovenote . All rights reserved.
//

#import "UIScrollView+LNRefresh.h"
#import <objc/runtime.h>

#define IS_IOS7_OR_LATER ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)

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
    _baseEdgeInsetsTop = 64;
    
    if (_viewType == RefreshViewTypePull) {
        _normalTips = NSLocalizedString(@"下拉刷新",nil);
        _overflowTips = NSLocalizedString(@"释放刷新",nil);
        _loadingTips = NSLocalizedString(@"下拉刷新",nil);
        
    }else if (_viewType == RefreshViewTypeLoadMore) {
        _normalTips = NSLocalizedString(@"加载更多",nil);
        _overflowTips = NSLocalizedString(@"释放刷新",nil);
        _loadingTips = NSLocalizedString(@"加载更多",nil);        
    }
    

    if (_viewType == RefreshViewTypePull) {
        self = [super initWithFrame:CGRectMake(0, -kRefreshHeight, scrollView.frame.size.width, kRefreshHeight)];
        _refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, kRefreshHeight)];
        
    }else if (_viewType == RefreshViewTypeLoadMore){
        self = [super initWithFrame:CGRectMake(0, scrollView.frame.size.height, scrollView.frame.size.width, kRefreshHeight)];
        _refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, kRefreshHeight)];
        
    }else{
        self = [super initWithFrame:CGRectMake(0, scrollView.frame.size.height, scrollView.frame.size.width, kRefreshHeight)];
    }
    
    self.refreshState = RefreshControlStateNormal;
    
    if (self) {
    
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
    }
    
    return self;
}

- (void)setRefreshState:(RefreshControlState)refreshState
{
    _refreshState = refreshState;
    if (refreshState == RefreshControlStateNormal) {
        _refreshLabel.text = _normalTips;
        _refreshIndicator.hidden = YES;
        _refreshLabel.hidden = NO;
        [_refreshIndicator stopAnimating];
        
    }else if (refreshState == RefreshControlStateLoading) {
        
        _refreshLabel.text = _loadingTips;
        _refreshIndicator.hidden = NO;
        _refreshLabel.hidden = YES;
        [_refreshIndicator startAnimating];
        
    }else if (refreshState == RefreshControlStateOverflow) {
        
        _refreshLabel.text = _overflowTips;
        _refreshIndicator.hidden = YES;
        _refreshLabel.hidden = NO;
        [_refreshIndicator stopAnimating];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.viewType == RefreshViewTypePull) {
        if (self.refreshState==RefreshControlStateOverflow) {
            self.refreshState = RefreshControlStateLoading;
            
            [UIView animateWithDuration:0.5 animations:^{
                UIEdgeInsets edgeInsets = self.scrollView.contentInset;
                if (IS_IOS7_OR_LATER) {
                    edgeInsets.top = _baseEdgeInsetsTop + kRefreshHeight;
                }else{
                    edgeInsets.top = kRefreshHeight;
                }
                self.scrollView.contentInset = edgeInsets;
            }];
        }
    }else if (self.viewType == RefreshViewTypeLoadMore){
        if (self.refreshState==RefreshControlStateOverflow) {
            self.refreshState = RefreshControlStateLoading;
           
            [UIView animateWithDuration:0.5 animations:^{
                UIEdgeInsets edgeInsets = self.scrollView.contentInset;
                edgeInsets.bottom = kRefreshHeight;
                self.scrollView.contentInset = edgeInsets;
            }];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    

    if (self.viewType == RefreshViewTypePull) {
        
        CGFloat offset = 0;
        if (IS_IOS7_OR_LATER) {
            offset = _baseEdgeInsetsTop;
        }
        
        if (self.scrollView.contentOffset.y+offset<=-kRefreshHeight) {
            if (self.refreshState==RefreshControlStateNormal) {
                self.refreshState = RefreshControlStateOverflow;
            }
        } else if (self.refreshState==RefreshControlStateOverflow) {
            self.refreshState = RefreshControlStateNormal;
        }
    }else if (self.viewType == RefreshViewTypeLoadMore && self.reachToEnd == NO){
        NSInteger height = self.scrollView.contentSize.height<self.scrollView.frame.size.height?self.scrollView.frame.size.height:self.scrollView.contentSize.height;
        if (self.scrollView.contentOffset.y>=kRefreshHeight+height-self.scrollView.frame.size.height) {
            if (self.refreshState==RefreshControlStateNormal) {
                self.refreshState = RefreshControlStateOverflow;
            }
        } else if (self.refreshState==RefreshControlStateOverflow) {
            self.refreshState = RefreshControlStateNormal;
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (self.refreshState==RefreshControlStateLoading && !_isRefreshing) {
        
        _isRefreshing = YES;
        if (_actionHandler) {
            _actionHandler();
        }
    }
}

- (void)triggerRefreshAnyWayInBackground
{
    if (_viewType == RefreshViewTypeLoadMore) {
        return;
    }
    
    if (self.refreshState == RefreshControlStateLoading) {
        return;
    }
    
    self.refreshState=RefreshControlStateLoading;
    _isRefreshing = YES;
    
    if (_actionHandler) {
        _actionHandler();
    }
}


- (void)triggerRefreshAnyWayWithControlHidden:(BOOL)hidden
{
    if (_viewType == RefreshViewTypeLoadMore) {
        return;
    }
    
    if (self.refreshState == RefreshControlStateLoading) {
        return;
    }
    self.refreshState=RefreshControlStateLoading;
    _isRefreshing = YES;
   
    if (hidden) {
        if (IS_IOS7_OR_LATER) {
            [self.scrollView setContentOffset:CGPointMake(0, -_baseEdgeInsetsTop) animated:NO];
        }else{
            [self.scrollView setContentOffset:CGPointZero animated:NO];
        }
    } else {
        UIEdgeInsets edgeInsets = self.scrollView.contentInset;
        if (IS_IOS7_OR_LATER) {
            edgeInsets.top = _baseEdgeInsetsTop + kRefreshHeight;
            [self.scrollView setContentOffset:CGPointMake(0, -_baseEdgeInsetsTop-kRefreshHeight) animated:NO];
        }else{
            edgeInsets.top = kRefreshHeight;
            [self.scrollView setContentOffset:CGPointMake(0, -kRefreshHeight) animated:YES];
        }
        self.scrollView.contentInset = edgeInsets;
    }
    if (_actionHandler) {
        _actionHandler();
    }
}

- (void)endRefreshWithAnimation:(BOOL)animation
{
    [self endRefreshWithInfo:nil delay:0 animation:animation];
}

- (void)endRefresh
{
    [self endRefreshWithInfo:nil delay:0 animation:YES];
}

- (void)endRefreshWithInfo:(NSString *)info
{
    [self endRefreshWithInfo:info delay:0 animation:YES];
}

- (void)endRefreshWithDelay:(CGFloat)delay
{
    [self endRefreshWithInfo:nil delay:delay animation:YES];
}
- (void)endRefreshWithInfo:(NSString *)info delay:(CGFloat)delay animation:(BOOL)animation
{
    _refreshLabel.hidden = NO;
    _refreshIndicator.hidden = YES;
      
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        _isRefreshing = NO;
        
        if (animation) {
            [UIView animateWithDuration:0.25 animations:^{
                if (self.viewType == RefreshViewTypePull) {
                    
                    if (self.scrollView.contentOffset.y < 0) {
                        if (IS_IOS7_OR_LATER) {
                            self.scrollView.contentOffset = CGPointMake(0, -_baseEdgeInsetsTop);
                        }else{
                            self.scrollView.contentOffset = CGPointZero;
                        }
                    }
                    
                }else if (self.viewType == RefreshViewTypeLoadMore){
                    self.scrollView.contentOffset = CGPointMake(0, self.scrollView.contentOffset.y + 1);  //add 1px for showing
                }
            } completion:^(BOOL finished) {
                
                if (info) {
                    _refreshLabel.text = info;
                }
                
                [UIView animateWithDuration:0.25 animations:^{
                    UIEdgeInsets insets = self.scrollView.contentInset;
                    if (IS_IOS7_OR_LATER) {
                        insets.top = _baseEdgeInsetsTop;
                    }else{
                        insets.top = 0;
                    }
                    if (self.viewType == RefreshViewTypeLoadMore){
                        insets.bottom = 0;
                    }
                    self.scrollView.contentInset = insets;
                }];
                self.refreshState = RefreshControlStateNormal;
            }];
        }else{
            
            if (info) {
                _refreshLabel.text = info;
            }
            
            [UIView animateWithDuration:0.25 animations:^{
                UIEdgeInsets insets = self.scrollView.contentInset;
                if (IS_IOS7_OR_LATER) {
                    insets.top = _baseEdgeInsetsTop;
                }else{
                    insets.top = 0;
                }
                self.scrollView.contentInset = insets;
                
            }];
            
            self.refreshState = RefreshControlStateNormal;
        }
        
    });
    return;
}
@end



static char UIScrollViewPullRefreshView;
static char UIScrollViewLoadMoreView;

@implementation UIScrollView (LNRefreshView)

@dynamic pullRefreshView;
@dynamic loadMoreView;

- (void)addPullRefreshWithActionHandler:(void (^)(void))actionHandler
{
    LNRefresh *pullRefreshView = [[LNRefresh alloc] initWithScrollView:self style:RefreshViewTypePull actionHandler:actionHandler];
    self.pullRefreshView = pullRefreshView;
}

- (void)setPullRefreshView:(LNRefresh *)pullRefreshView
{
    objc_setAssociatedObject(self, &UIScrollViewPullRefreshView,
                             pullRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
}
- (LNRefresh *)pullRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullRefreshView);
}

- (void)addLoadMoreWithActionHandler:(void (^)(void))actionHandler
{
    LNRefresh *loadMoreView = [[LNRefresh alloc] initWithScrollView:self style:RefreshViewTypeLoadMore actionHandler:actionHandler];
    self.loadMoreView = loadMoreView;
    [self addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
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

- (void)removeRefresh
{
    if (self.loadMoreView) {
        [self removeObserver:self forKeyPath:@"contentSize"];
    }
}

#pragma mark UIScrollerViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [scrollView.pullRefreshView scrollViewDidEndDecelerating:scrollView];
    [scrollView.loadMoreView scrollViewDidEndDecelerating:scrollView];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [scrollView.pullRefreshView scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    [scrollView.loadMoreView scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [scrollView.pullRefreshView scrollViewDidScroll:scrollView];
    [scrollView.loadMoreView scrollViewDidScroll:scrollView];
}

@end

