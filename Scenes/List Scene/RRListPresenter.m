//
//  RRListPresenter.m
//  rework-reader
//
//  Created by 张超 on 2019/2/21.
//  Copyright © 2019 orzer. All rights reserved.
//

#import "RRListPresenter.h"
#import "RRFeedInfoListModel.h"
#import "RRFeedInfoListOtherModel.h"
#import "RPDataManager.h"
@import ui_base;
#import "RRCoreDataModel.h"
#import "RRFeedArticleCell.h"
#import "RRFeedArticleModel.h"
#import "RRFeedInfoInputer.h"
#import "RRProvideDataProtocol.h"
#import "RRListInputer.h"
#import "RRFeedLoader.h"
#import "RRFeedAction.h"
#import "PWToastView.h"
@import SafariServices;
@import oc_string;
@import oc_util;
@import DateTools;

@interface RRListPresenter ()
{
    
}

@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* modelTitle;

@property (nonatomic, strong) RRFeedInfoListModel* infoModel;
@property (nonatomic, strong) RRFeedInfoListOtherModel* styleModel;

@property (nonatomic, strong) RRFeedInfoInputer* inputer;
@property (nonatomic, strong) RRListInputer* inputerCoreData;

@property (nonatomic, strong) NSMutableArray* hashTable;

@end

@implementation RRListPresenter

- (NSMutableArray *)hashTable
{
    if (!_hashTable) {
        _hashTable = [[NSMutableArray alloc] init];
    }
    return _hashTable;
}


- (void)viewWillAppear:(BOOL)animated
{
    [self.hashTable removeAllObjects];
//    NSArray* a = self.inputerCoreData.allModels;
//    [a enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        [self.hashTable addObject:obj];
//    }];
    [self.hashTable addObjectsFromArray:self.inputerCoreData.allModels];
}

- (RRFeedInfoInputer *)inputer
{
    if (!_inputer) {
        _inputer = [[RRFeedInfoInputer alloc] init];
    }
    return _inputer;
}

- (RRListInputer *)inputerCoreData
{
    if (!_inputerCoreData) {
        _inputerCoreData = [[RRListInputer alloc] init];
    }
    return _inputerCoreData;
}

- (id)mvp_inputerWithOutput:(id<MVPOutputProtocol>)output
{
    return self.inputerCoreData;
}

- (void)mvp_initFromModel:(MVPInitModel *)model
{
    id m = model.userInfo[@"model"];
    if (!m) {
        return;
    }
    if ([m isKindOfClass:[RRFeedInfoListModel class]]) {
        RRFeedInfoListModel* mm = m;
        self.modelTitle = self.title = mm.title;
        self.infoModel = mm;
        self.inputerCoreData.feed = mm.feed;
    }
    else if([m isKindOfClass:[RRFeedInfoListOtherModel class]])
    {
        RRFeedInfoListOtherModel* mm = m;
        self.modelTitle = self.title = mm.title;
        self.styleModel = mm;
        self.inputerCoreData.model = mm;
    }
}

- (void)deleteIt
{
    __weak typeof(self) weakSelf = self;
    [RRFeedAction delFeed:self.infoModel.feed view:(id)self.view finish:^{
         [(id)weakSelf.view mvp_popViewController:nil];
    }];
}

- (void)deleteIt2
{
    NSSet* s = [self.infoModel.feed.articles filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"liked = YES"]];
    NSString* m = [NSString stringWithFormat:@"共有%ld篇文章",self.infoModel.feed.articles.count];
    if (s.count > 0) {
        m = [NSString stringWithFormat:@"共有%ld篇文章，其中有%ld篇收藏不会删除",self.infoModel.feed.articles.count,s.count];
    }
    
    UI_ActionSheet()
    .titled([NSString stringWithFormat:@"确认删除「%@」?",self.infoModel.feed.title])
    .descripted(m)
    .cancel(@"取消", ^(UIAlertAction * _Nonnull action) {
        
    })
    .recommend(@"删除", ^(UIAlertAction * _Nonnull action, UIAlertController * _Nonnull alert) {
        [self delFeedInfo:self.infoModel.feed];
    })
    .show((id)self.view);
}

- (void)delFeedInfo:(EntityFeedInfo*)info
{
    // step 1 删除文章
    __weak typeof(self) weakSelf = self;
    NSPredicate* p = [NSPredicate predicateWithFormat:@"feed = %@ and liked = NO",info];
    [[RPDataManager sharedManager] delData:@"EntityFeedArticle" predicate:p key:nil value:nil beforeDel:^BOOL(__kindof NSManagedObject * _Nonnull o) {
        return YES;
    } finish:^(NSUInteger count, NSError * _Nonnull e) {
        NSLog(@"delete %ld articles",count);
        if (!e) {
            [weakSelf delFeedInfoStep2:info];
        }
    }];
}

- (void)delFeedInfoStep2:(EntityFeedInfo*)info
{
    // step 2 删除订阅源
    [[RPDataManager sharedManager] delData:info relationKey:nil beforeDel:^BOOL(__kindof NSManagedObject * _Nonnull o) {
        
        return YES;
    } finish:^(NSUInteger count, NSError * _Nonnull e) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!e) {
                [(id)self.view hudSuccess:@"删除成功"];
                [(id)self.view mvp_popViewController:nil];
            }
            else {
                [(id)self.view hudFail:@"删除失败"];
            }
        });
    }];
}

- (void)refreshData:(UIRefreshControl*)sender
{
    [self updateFeedData:^(NSInteger x) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //                [P]
            if (x == 0) {
                [PWToastView showText:@"没有更新的订阅了"];
            }
            else {
                [PWToastView showText:[NSString stringWithFormat:@"更新了%ld篇订阅",x]];
            }
            [sender endRefreshing];
            
            [self.hashTable removeAllObjects];
            [self.hashTable addObjectsFromArray:self.inputerCoreData.allModels];
        });
    }];
   
}

- (void)updateFeedData:(void (^)(NSInteger x))finished
{
    if (self.infoModel) {
        __block NSMutableArray* temp = [[NSMutableArray alloc] init];
        [[RRFeedLoader sharedLoader] loadFeed:[self.infoModel.feed.url absoluteString] infoBlock:^(MWFeedInfo * _Nonnull info) {
            
        } itemBlock:^(MWFeedItem * _Nonnull item) {
            NSLog(@"%@",item.title);
            
            // AllReadyTODO:新增文章
            RRFeedArticleModel* m = [[RRFeedArticleModel alloc] initWithItem:item];
            [temp addObject:m];
            
        } errorBlock:^(NSError * _Nonnull error) {
            
        } finishBlock:^{
            
            [RRFeedAction insertArticle:temp withFeed:self.infoModel.feed finish:^(NSUInteger x) {
                if (finished) {
                    finished(x);
                }
            }];
            
            
        } needUpdateIcon:NO];
    }
    else if(self.styleModel)
    {
        [self updateFeedData2:finished];
    }
}


- (void)updateFeedData2:(void (^)(NSInteger x))finished
{
    NSArray* all = [self.styleModel.readStyle.feeds allObjects];
    if (!all) {
        all = [[RPDataManager sharedManager] getAll:@"EntityFeedInfo" predicate:nil key:nil value:nil sort:@"sort" asc:YES];
    }
    all =
    all.filter(^BOOL(RRFeedInfoListModel*  _Nonnull x) {
        NSString* key = [NSString stringWithFormat:@"UPDATE_%@",x.url];
        NSInteger lastU = [MVCKeyValue getIntforKey:key];
        if (lastU != 0) {
            NSDate* d = [NSDate dateWithTimeIntervalSince1970:lastU];
            NSLog(@"last %@ %@",d,@([d timeIntervalSinceDate:[NSDate date]]));
            if ([d timeIntervalSinceDate:[NSDate date]] > - 60 * 10) {
                return NO;
            }
        }
        
        if (x.usettl) {
            NSUInteger ttl = [x.ttl integerValue];
            NSDate* d = [x.updateDate dateByAddingMinutes:ttl];
            if ([d timeIntervalSinceDate:[NSDate date]] > 0) {
                return NO;
            }
        }
        return YES;
    })
    .map(^id _Nonnull(RRFeedInfoListModel*  _Nonnull x) {
        return [x.url absoluteString];
    });
    
    [[RRFeedLoader sharedLoader] refresh:all endRefreshBlock:^{
//        [sender endRefreshing];
        if (finished) {
            finished(0);
        }
    } finishBlock:^(NSUInteger all, NSUInteger error, NSUInteger article) {
        if (finished) {
            finished(0);
        }
    }];
}


- (void)mvp_action_selectItemAtIndexPath:(NSIndexPath *)path
{
    id model = [[self inputerCoreData] mvp_modelAtIndexPath:path];
    if ([model isKindOfClass:[RRFeedArticleModel class]]) {
        [self loadArticle:model];
    }
    else if([model isKindOfClass:[EntityFeedArticle class]])
    {
//        RRFeedArticleModel* mm = [[RRFeedArticleModel alloc] initWithEntity:model];
//        mm.feedEntity = [(EntityFeedArticle*)model feed];
        [self loadArticle:model];
    }
}

- (void)loadArticle:(id)model
{
    id feed = nil;
 
    if ([model isKindOfClass:[RRFeedArticleModel class]]) {
        feed = [model feedEntity];
        RRFeedArticleModel* m = model;

        
    }
    else if([model isKindOfClass:[EntityFeedArticle class]])
    {
        feed = [model feed];
        EntityFeedInfo* i = feed;
        EntityFeedArticle* a = model;

        if (i.usesafari) {
            
            [RRFeedAction readArticle:a.uuid];
            
            SFSafariViewControllerConfiguration* c = [[SFSafariViewControllerConfiguration alloc] init];
            c.entersReaderIfAvailable = YES;
            SFSafariViewController* s = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:a.link] configuration:c];
            [self.view mvp_presentViewController:s animated:YES completion:^{
            }];
            return;
        }
    }
    
    if (!feed) {
        feed = [NSNull null];
    }
    id web = [MVPRouter viewForURL:@"rr://web" withUserInfo:@{@"model":model,@"feed":feed}];
    if([web conformsToProtocol:@protocol(RRProvideDataProtocol)])
    {
        id <RRProvideDataProtocol> webView = web;
        __weak typeof(self) weakSelf = self;
        [webView setLastArticle:^id _Nullable(id  _Nonnull current) {
            return [weakSelf last:current];
        }];
        [webView setLastFeed:^id _Nullable(id  _Nonnull current) {
            return [weakSelf lastFeed:current];
        }];
        [webView setNextFeed:^id _Nullable(id  _Nonnull current) {
            return [weakSelf nextFeed:current];
        }];
        [webView setNextArticle:^id _Nullable(id  _Nonnull current) {
            return [weakSelf next:current];
        }];
    }
    [self.view mvp_pushViewController:web];
}



- (id)lastFeed:(id)current
{
    id data = [self last:current];
    if ([data isKindOfClass:[RRFeedArticleModel class]]) {
        return [data feedEntity];
    }
    else if([data isKindOfClass:[EntityFeedArticle class]])
    {
        return [data feed];
    }
    return nil;
}

- (id)nextFeed:(id)current
{
    id data = [self next:current];
    if ([data isKindOfClass:[RRFeedArticleModel class]]) {
        return [data feedEntity];
    }
    else if([data isKindOfClass:[EntityFeedArticle class]])
    {
        return [data feed];
    }
    return nil;
}

- (id)last:(id)current
{
//    NSArray* all = [self.inputerCoreData allModels];
//    NSArray* all = [self.hashTable allObjects];
    NSArray* all = self.hashTable;
    NSInteger x = [all indexOfObject:current];
    //    NSLog(@"%@ %ld" ,current,x);
    if (x == 0) {
        return nil;
    }
    NSInteger lastidx = x-1;
    id last = [all objectAtIndex:lastidx];
    if ([last isKindOfClass:[RRFeedArticleModel class]] || [last isKindOfClass:[EntityFeedArticle class]]) {
        return last;
    }
    return nil;
}

- (id)next:(id)current
{
//    NSArray* all = [self.inputerCoreData allModels];
//    NSArray* all = [self.hashTable allObjects];
    NSArray* all = self.hashTable;
    NSInteger x = [all indexOfObject:current];
    //    NSLog(@"%@ %ld" ,current,x);
    if (x == all.count - 1) {
        return nil;
    }
    NSInteger lastidx = x+1;
    id last = [all objectAtIndex:lastidx];
    if ([last isKindOfClass:[RRFeedArticleModel class]] || [last isKindOfClass:[EntityFeedArticle class]]) {
        return last;
    }
    return nil;
}


- (void)changeFeedValue:(id)value forKey:(NSString*)key void:(void (^)(NSError*e))finish
{
    __weak typeof(self) weakSelf = self;
    EntityFeedInfo* feed = self.infoModel.feed;
    [[RPDataManager sharedManager] updateClass:@"EntityFeedInfo" queryKey:@"uuid" queryValue:feed.uuid keysAndValues:@{key:value} modify:^id _Nonnull(id  _Nonnull key, id  _Nonnull value) {
        return value;
    } finish:^(__kindof NSManagedObject * _Nonnull obj, NSError * _Nonnull e) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController* v = (id)weakSelf.view;
            if (e) {
                [v hudFail:@"修改失败"];
            }
            else {
                [v hudSuccess:@"修改成功"];
            }
            if (finish) {
                finish(e);
            }
        });
    }];
}

- (void)configit
{
    EntityFeedInfo* feed = self.infoModel.feed;
    BOOL usetll = feed.usettl;
    BOOL useauto = feed.useautoupdate;
    BOOL usesafari = feed.usesafari;
    
    __weak typeof(self) weakSelf = self;
    UI_ActionSheet()
    .titled(@"设置")
    .recommend(@"修改标题", ^(UIAlertAction * _Nonnull action, UIAlertController * _Nonnull alert) {
        UI_Alert()
        .titled(@"修改标题")
        .recommend(@"确定", ^(UIAlertAction * _Nonnull action, UIAlertController * _Nonnull alert) {
            UITextField* t = alert.textFields[0];
            [weakSelf changeFeedValue:t.text forKey:@"title" void:^(NSError *e) {
                if (!e) {
                    weakSelf.title = t.text;
                }
            }];
        })
        .cancel(@"取消", ^(UIAlertAction * _Nonnull action) {
            
        })
        .input(@"标题", ^(UITextField * _Nonnull field) {
            field.text = feed.title;
        })
        .show((id)self.view);
    })
    .action(usetll?@"关闭缓存期内更新":@"开启缓存期内更新", ^(UIAlertAction * _Nonnull action, UIAlertController * _Nonnull alert) {
        
        [weakSelf changeFeedValue:@(!usetll) forKey:@"usettl" void:^(NSError *e) {
            
        }];
    })
    .action(useauto?@"关闭自动更新文章":@"开启自动更新文章", ^(UIAlertAction * _Nonnull action, UIAlertController * _Nonnull alert) {
        
        [weakSelf changeFeedValue:@(!useauto) forKey:@"useautoupdate" void:^(NSError *e) {
            
        }];
    })
    .action(usesafari?@"关闭直接阅读原文":@"开启直接阅读原文", ^(UIAlertAction * _Nonnull action, UIAlertController * _Nonnull alert) {
        [weakSelf changeFeedValue:@(!usesafari) forKey:@"usesafari" void:^(NSError *e) {
            
        }];
    })
    .cancel(@"取消", ^(UIAlertAction * _Nonnull action) {
        
    })
    .show((id)self.view);
    
}


@end
