//
//  RRTest.m
//  rework-reader
//
//  Created by 张超 on 2019/1/28.
//  Copyright © 2019 orzer. All rights reserved.
//

#import "RRTest.h"
#import "RRFeedLoader.h"
#import "RRGetWebIconOperation.h"
@import NaturalLanguage;
@import ui_base;
#import "RPDataManager.h"
#import "RRCoreDataModel.h"

@implementation RRTest

- (void)feed
{
    [[RRFeedLoader sharedLoader] loadOfficalWithInfoBlock:^(MWFeedInfo * _Nonnull info) {
        
    } itemBlock:^(MWFeedItem * _Nonnull item) {
        NSLog(@"%@",item);
    } errorBlock:^(NSError * _Nonnull error) {
        
    } finishBlock:^{
        
    }];
}

- (void)nl
{
    
    if (@available(iOS 12.0, *)) {
        
        // 语言种类判断
        NLLanguageRecognizer * r = [[NLLanguageRecognizer alloc] init];
        [r processString:@"困死了去睡觉了"];
        NLLanguage l = r.dominantLanguage;
        NSLog(@"%@",l);
        NSDictionary* d = [r languageHypothesesWithMaximum:2];
        NSLog(@"%@",d);
        
        // 分词
        NLTokenizer* tokenizer = [[NLTokenizer alloc] initWithUnit:NLTokenUnitWord];
        NSString* str = @"我困死了，我要去睡觉了";
        NSRange range = NSMakeRange(0, str.length);
        tokenizer.string = str;
        NSArray* allWords = [tokenizer tokensForRange:range];
        NSLog(@"%@",allWords);
        
        // 文本标签
        NLLanguageRecognizer * r2 = [[NLLanguageRecognizer alloc] init];
        NLTagger* tagger = [[NLTagger alloc] initWithTagSchemes:@[NLTagSchemeNameType]];
        NSString* str2 = @"Prince Harry and Meghan have an apple and a TV.";
        [r2 processString:str2];
        NLLanguage l2 = r2.dominantLanguage;
        NSRange range2 = NSMakeRange(0, str2.length);
        tagger.string = str2;
        [tagger setLanguage:l2 range:range2];
//        NSArray* tags = [tagger tagsInRange:range2 unit:NLTokenUnitWord scheme:NSLinguisticTagSchemeNameType options:NLTaggerOmitWhitespace tokenRanges:nil];
//        [tags enumerateObjectsUsingBlock:^(NLTag*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//
//        }];
        [tagger enumerateTagsInRange:range2 unit:NLTokenUnitWord scheme:NLTagSchemeNameType options:NLTaggerOmitWhitespace|NLTaggerJoinNames usingBlock:^(NLTag  _Nullable tag, NSRange tokenRange, BOOL * _Nonnull stop) {
            NSLog(@"%@",[str2 substringWithRange:tokenRange]);
            NSLog(@"%@",tag);
            NSLog(@"--");
        }];
    }
}


- (void)icon
{
    RRGetWebIconOperation* o = [[RRGetWebIconOperation alloc] init];
    o.host = [NSURL URLWithString:@"https://www.cnblogs.com/lijIT/p/8980348.html"];
    [o setGetIconBlock:^(NSString * _Nonnull icon) {
        NSLog(@"%@",icon);
    }];
    [o start];
}


- (void)allArticle
{
   NSArray* x = [[RPDataManager sharedManager] getAll:@"EntityFeedArticle" predicate:nil key:nil value:nil sort:@"sort" asc:YES];
 
    [x enumerateObjectsUsingBlock:^(EntityFeedArticle*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"%@ %@ %@",obj.title,obj.lastread,obj.uuid);
    }];
}

- (void)allFeed
{
    NSArray* x = [[RPDataManager sharedManager] getAll:@"EntityFeedInfo" predicate:nil key:nil value:nil sort:@"sort" asc:YES];
    
    [x enumerateObjectsUsingBlock:^(EntityFeedInfo*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"%@ %@",obj.title,obj.uuid);
    }];
}
@end
