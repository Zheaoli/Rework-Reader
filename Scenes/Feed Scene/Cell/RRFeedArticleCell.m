//
//  RRFeedArticleCell.m
//  rework-reader
//
//  Created by 张超 on 2019/2/14.
//  Copyright © 2019 orzer. All rights reserved.
//

#import "RRFeedArticleCell.h"
#import "RRFeedArticleModel.h"
#import "RRFeedLoader.h"
@import DateTools;
@import SDWebImage;
@import oc_string;
#import "RRCoreDataModel.h"
//@import YYKit;
@implementation RRFeedArticleCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.i1.image = [UIImage new];
    self.i2.image = [UIImage new];

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)loadModel:(id<MVPModelProtocol>)model
{
    [super loadModel:model];
    
    if ([model isKindOfClass:[RRFeedArticleModel class]]) {
        RRFeedArticleModel* m = model;
        self.titleLabel.text = m.title;
        NSDate* date = m.date ? m.date : m.updated;
        NSString* des = @"";
        if (date) {
            des = [NSString stringWithFormat:@"%@ · %@  · ",[date timeAgoSinceNow],[[RRFeedLoader sharedLoader].shrotDateAndTimeFormatter stringFromDate:date]];
        }
        
        if (m.summary.length > 30 || m.content.length > 30) {
            NSString* temp = m.content.length > 30 ? m.content : m.summary;
            temp = [temp stringByConvertingHTMLToPlainText];
            //        NSLog(@"%@ %@",@(temp.length),temp);
            des = [des stringByAppendingFormat:@"%.1f分钟", (float)temp.length/300];
        }
        self.dateLabel.text = des;
        
        if (m.feed) {
            self.feedLabel.text = m.feed.title;
            
            if (m.feed.icon) {
                [self.iconView sd_setImageWithURL:[NSURL URLWithString:m.feed.icon] placeholderImage:[UIImage imageNamed:@"favicon"]];
            }
            else {
                [self.iconView setImage:[UIImage imageNamed:@"favicon"]];
            }
        }
        else if(m.feedEntity)
        {
            self.feedLabel.text = m.feedEntity.title;
            
            if (m.feedEntity.icon) {
                [self.iconView sd_setImageWithURL:[NSURL URLWithString:m.feedEntity.icon] placeholderImage:[UIImage imageNamed:@"favicon"]];
            }
            else {
                [self.iconView setImage:[UIImage imageNamed:@"favicon"]];
            }
        }
    }
    else if([model isKindOfClass:[EntityFeedArticle class]])
    {
        EntityFeedArticle* m = model;
        self.titleLabel.text = m.title;
        NSDate* date = m.date ? m.date : m.updated;
        NSString* des = @"";
        if (date) {
            des = [NSString stringWithFormat:@"%@ · %@  · ",[date timeAgoSinceNow],[[RRFeedLoader sharedLoader].shrotDateAndTimeFormatter stringFromDate:date]];
        }
        
        if (m.summary.length > 30 || m.content.length > 30) {
            NSString* temp = m.content.length > 30 ? m.content : m.summary;
            temp = [temp stringByConvertingHTMLToPlainText];
            //        NSLog(@"%@ %@",@(temp.length),temp);
            des = [des stringByAppendingFormat:@"%.1f分钟", (float)temp.length/300];
        }
        self.dateLabel.text = des;
        
        if (m.feed) {
            self.feedLabel.text = m.feed.title;
            
            if (m.feed.icon) {
                [self.iconView sd_setImageWithURL:[NSURL URLWithString:m.feed.icon] placeholderImage:[UIImage imageNamed:@"favicon"]];
            }
            else {
                [self.iconView setImage:[UIImage imageNamed:@"favicon"]];
            }
        }
        else {
            [self.iconView setImage:[UIImage imageNamed:@"favicon"]];
            self.feedLabel.text = @"无订阅源";
        }
        
//        NSLog(@"%@ %@",@(m.liked),m.lastread);
        
        if (m.liked) {
            self.i1.image = [UIImage imageNamed:@"icon_i3"];
        }
        else {
            self.i1.image = [UIImage new];
        }
        if (!m.lastread) {
            if (m.liked) {
                [self.i2 setImage:[UIImage imageNamed:@"icon_i2"]];
            }
            else {
                [self.i1 setImage:[UIImage imageNamed:@"icon_i2"]];
            }
            
        }
        else {
            if (m.liked) {
                [self.i2 setImage:[UIImage new]];
            }
            else {
                [self.i1 setImage:[UIImage new]];
            }
        }
    }
    
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.i1.image = [UIImage new];
    self.i2.image = [UIImage new];
}

@end
