//
//  OSCNewsDetails.m
//  iosapp
//
//  Created by chenhaoxiang on 10/31/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "OSCNewsDetails.h"

static NSString *kID = @"id";
static NSString *kTitle = @"title";
static NSString *kURL = @"url";
static NSString *kBody = @"body";
static NSString *kCommentCount = @"commentCount";
static NSString *kAuthor = @"author";
static NSString *kAuthorID = @"authorid";
static NSString *kPubDate = @"pubDate";
static NSString *kSoftwareLink = @"softwarelink";
static NSString *kSoftwareName = @"softwareName";
static NSString *kFavorite = @"favorite";
static NSString *kRelatives = @"relativies";
static NSString *kRelative = @"relative";
static NSString *kRTitle = @"rtitle";
static NSString *kRURL = @"rurl";

@implementation OSCNewsDetails

- (instancetype)initWithXML:(ONOXMLElement *)xml
{
    self = [super init];
    
    if (self) {
        _newsID = [[[xml firstChildWithTag:kID] numberValue] longLongValue];
        _title = [[xml firstChildWithTag:kTitle] stringValue];
        _url = [NSURL URLWithString:[[xml firstChildWithTag:kURL] stringValue]];
        _body = [[xml firstChildWithTag:kBody] stringValue];
        _commentCount = [[[xml firstChildWithTag:kCommentCount] numberValue] intValue];
        _author = [[xml firstChildWithTag:kAuthor] stringValue];
        _authorID = [[[xml firstChildWithTag:kAuthorID] numberValue] longLongValue];
        _pubDate = [[xml firstChildWithTag:kPubDate] stringValue];
        _softwareLink = [NSURL URLWithString:[[xml firstChildWithTag:kSoftwareLink] stringValue]];
        _softwareName = [[xml firstChildWithTag:kSoftwareName] stringValue];
        _isFavorite = [[[xml firstChildWithTag:kFavorite] numberValue] boolValue];
        NSMutableArray *mutableRelatives = [NSMutableArray new];
        NSArray *relativesXML = [[xml firstChildWithTag:kRelatives] childrenWithTag:kRelative];
        for (ONOXMLElement *relativeXML in relativesXML) {
            NSString *rTitle = [[relativeXML firstChildWithTag:kRTitle] stringValue];
            NSString *rURL = [[relativeXML firstChildWithTag:kRURL] stringValue];
            [mutableRelatives addObject:@[rTitle, rURL]];
        }
        _relatives = [NSArray arrayWithArray:mutableRelatives];
    }
    
    return self;
}

@end
