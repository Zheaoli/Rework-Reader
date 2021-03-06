//
//  RRReadStyle.m
//  rework-reader
//
//  Created by 张超 on 2019/2/22.
//  Copyright © 2019 orzer. All rights reserved.
//

#import "RRReadStyle.h"
@import DateTools;
@implementation RRReadStyle

- (instancetype)initWithEntity:(EntityFeedStyle*)style;
{
    self = [super init];
    if (self) {
        self.title = style.title;
        self.feeds = style.feeds;
        self.daylimit = style.dayLimit;
        self.onlyUnread = style.unread;
        self.liked = style.liked;
    }
    return self;
}


- (NSArray<NSSortDescriptor*>*)sort
{
    NSSortDescriptor* d1 = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSSortDescriptor* d2 = [[NSSortDescriptor alloc] initWithKey:@"updated" ascending:NO];
    NSSortDescriptor* d3 = [[NSSortDescriptor alloc] initWithKey:@"likedTime" ascending:NO];
    NSSortDescriptor* d4 = [[NSSortDescriptor alloc] initWithKey:@"lastread" ascending:NO];
    NSSortDescriptor* d5 = [[NSSortDescriptor alloc] initWithKey:@"sort" ascending:NO];
    if (self.feed) {
        return @[d5,d1,d2];
    }
    else {
        if (self.onlyReaded) {
            return @[d4];
        }
        if (self.liked) {
            return @[d3];
        }
    }
    return @[d1,d2,d5];
}


- (NSPredicate *)predicate
{
    if (self.feed) {
        return [NSPredicate predicateWithFormat:@"feed = %@",self.feed];
    }
    else {
        NSMutableString* m = [[NSMutableString alloc] init];
        if (self.feeds && self.feeds.count > 0) {
            [m appendString:@"("];
            [self.feeds enumerateObjectsUsingBlock:^(EntityFeedInfo*  _Nonnull obj, BOOL * _Nonnull stop) {
                if (m.length != 0) {
                    [m appendString:@" || "];
                }
                [m appendFormat:@"feed.uuid = %@",obj.uuid];
            }];
            [m appendString:@")"];
        }
        if (self.onlyUnread) {
            if (m.length != 0) {
                [m appendString:@" && "];
            }
            [m appendString:@"lastread = nil"];
        }
        if (self.onlyReaded) {
            if (m.length != 0) {
                [m appendString:@" && "];
            }
            [m appendString:@"lastread != nil"];
        }
        if (self.liked) {
            if (m.length != 0) {
                [m appendString:@" && "];
            }
            [m appendString:@"liked = true"];
        }
        if (self.daylimit > 0) {
            if (m.length != 0) {
                [m appendString:@" && "];
            }
            NSDate* d = [[NSDate date] dateBySubtractingDays:self.daylimit-1];
            [m appendFormat:@"date > %%@"];
            NSPredicate * pp = [NSPredicate predicateWithFormat:m,d];
            NSLog(@"%@",pp.predicateFormat);
            return pp;
        }
        //        NSLog(@"%@",m);
        return [NSPredicate predicateWithFormat:m];
    }
    return [NSPredicate predicateWithFormat:@"feed = %@",self.feed];
}

@end
