//
//  UIScrollView+LNRefresh.h
//  lovenote
//
//  created by Dskyu  on 13-05-07.
//  Copyright (c) 2013年 Lovenote . All rights reserved.
//

#import <UIKit/UIKit.h>

@class LNRefresh;

@interface UIScrollView (LNRefreshView) <UIScrollViewDelegate>

- (void)addPullRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)addLoadMoreWithActionHandler:(void (^)(void))actionHandler;

- (void)remove;

@property (nonatomic, strong) LNRefresh *pullToRefreshView;
@property (nonatomic, strong) LNRefresh *loadMoreView;

@end


typedef enum {
    RefreshControlStateNormal = 0,RefreshControlStateOverflow,RefreshControlStateLoading
}RefreshControlState;
typedef enum {
    RefreshViewTypePull = 0,RefreshViewTypeLoadMore
}RefreshViewType;

@interface LNRefresh : UIView

@property (nonatomic, readonly) RefreshControlState refreshState;
@property (nonatomic, assign) RefreshViewType viewType;
@property (nonatomic, assign) BOOL reachToEnd;
@property (nonatomic, strong) UILabel *refreshLabel;
@property (nonatomic, strong) UIActivityIndicatorView *refreshIndicator;
@property (nonatomic, weak, readonly) UIScrollView *scrollView;


- (void)triggerRefreshAnyWayWithControlHidden:(BOOL)hidden;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)endRefresh;
- (void)endRefreshWithInfo:(NSString *)info;
- (void)endRefreshWithDelay:(CGFloat)delay;
- (void)endRefreshWithInfo:(NSString *)info delay:(CGFloat)delay;

@end