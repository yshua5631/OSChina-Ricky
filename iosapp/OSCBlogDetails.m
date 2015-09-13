//
//  OSCBlogDetails.m
//  iosapp
//
//  Created by chenhaoxiang on 10/31/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "OSCBlogDetails.h"

static NSString *kID = @"id";
static NSString *kTitle = @"title";
static NSString *kURL = @"url";
static NSString *kBody = @"body";
static NSString *kCommentCount = @"commentCount";
static NSString *kAuthor = @"author";
static NSString *kAuthorID = @"authorid";
static NSString *kPubDate = @"pubDate";
static NSString *kFavorite = @"favorite";
static NSString *kWhere = @"where";
static NSString *kDocumentType = @"documentType";

@implementation OSCBlogDetails

- (instancetype)initWithXML:(ONOXMLElement *)xml
{
    self = [super init];
    
    if (self) {
        _blogID = [[[xml firstChildWithTag:kID] numberValue] longLongValue];
        _title = [[xml firstChildWithTag:kTitle] stringValue];
        _url = [NSURL URLWithString:[[xml firstChildWithTag:kURL] stringValue]];
        _body = [[xml firstChildWithTag:kBody] stringValue];
        _commentCount = [[[xml firstChildWithTag:kCommentCount] numberValue] intValue];
        _author = [[xml firstChildWithTag:kAuthor] stringValue];
        _authorID = [[[xml firstChildWithTag:kAuthorID] numberValue] longLongValue];
        _pubDate = [[xml firstChildWithTag:kPubDate] stringValue];
        _isFavorite = [[[xml firstChildWithTag:kFavorite] numberValue] boolValue];
        _where = [[xml firstChildWithTag:kWhere] stringValue];
        _documentType = [[[xml firstChildWithTag:kDocumentType] numberValue] intValue];
    }
    
    return self;
}

@end
