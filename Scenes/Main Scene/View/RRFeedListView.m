//
//  RRFeedListView.m
//  rework-reader
//
//  Created by 张超 on 2019/1/28.
//  Copyright © 2019 orzer. All rights reserved.
//

#import "RRFeedListView.h"
@import ui_util;
#import "RREmpty.h"

@interface RRFeedListView ()

@end

@implementation RRFeedListView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}

- (Class)mvp_presenterClass
{
    return NSClassFromString(@"RRFeedListPresenter");
}

- (void)mvp_initFromModel:(MVPInitModel *)model
{
    
}

- (void)mvp_configMiddleware
{
    [super mvp_configMiddleware];
    
    MVPTableViewOutput* o = self.outputer;
    [o mvp_registerNib:[UINib nibWithNibName:@"RRFeedInfoListCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"feedCell"];
    [o mvp_registerNib:[UINib nibWithNibName:@"RRTitleCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"titleCell"];
    self.empty = [[RREmpty alloc] init];
    
    [o mvp_bindTableRefreshActionName:@"refreshData:"];
}

- (void)mvp_bindData
{
    [self.presenter mvp_bindBlock:^(__kindof UIViewController* view, id value) {
        view.title = value;
    } keypath:@"title"];
}

- (Class)mvp_outputerClass
{
    return NSClassFromString(@"RRTableOutput");
}

- (void)mvp_configOther
{
    UIBarButtonItem* bSetting = [self mvp_buttonItemWithActionName:@"openSetting" title:@"更多内容"];
    self.navigationItem.leftBarButtonItem = bSetting;
    
    UIBarButtonItem* bSearch = [self mvp_buttonItemWithSystem:UIBarButtonSystemItemSearch actionName:@"openSearch" title:@"搜索"];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem* bAddRss = [self mvp_buttonItemWithActionName:@"addRSS" title:@"添加订阅源"];
//    UIBarButtonItem* bAddHub = [self mvp_buttonItemWithActionName:@"addHub" title:@"添加阅读规则"];
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = @[space,bAddRss];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:1 target:nil action:nil];
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    [super motionBegan:motion withEvent:event];
    if (motion == UIEventSubtypeMotionShake) {
#ifdef DEBUG
        [UUTest showInView:self];
#endif
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
    
    if ([self.presenter respondsToSelector:@selector(viewWillAppear:)]) {
        [(id)self.presenter viewWillAppear:animated];
    }
//    [self.navigationController.navigationBar setPrefersLargeTitles:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [self.navigationController.navigationBar setPrefersLargeTitles:YES];
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
