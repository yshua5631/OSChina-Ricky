//
//  OSCSoftwareDetails.m
//  iosapp
//
//  Created by chenhaoxiang on 11/3/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "OSCSoftwareDetails.h"

static NSString * const kID = @"id";
static NSString * const kTitle = @"title";
static NSString * const kExtensionTitle = @"extensionTitle";
static NSString * const kLicense = @"license";
static NSString * const kBody = @"body";
static NSString * const kOS = @"os";
static NSString * const kLanguage = @"language";
static NSString * const kRecordTime = @"recordtime";
static NSString * const kURL = @"url";
static NSString * const kHomepage = @"homepage";
static NSString * const kDocument = @"document";
static NSString * const kDownload = @"download";
static NSString * const kLogo = @"logo";
static NSString * const kFavorite = @"favorite";
static NSString * const kTweetCount = @"tweetCount";

@implementation OSCSoftwareDetails

- (instancetype)initWithXML:(ONOXMLElement *)xml
{
    self = [super init];
    
    if (self) {
        _softwareID = [[[xml firstChildWithTag:kID] numberValue] longLongValue];
        _title = [[xml firstChildWithTag:kTitle] stringValue];
        _extensionTitle = [[xml firstChildWithTag:kExtensionTitle] stringValue];
        _license = [[xml firstChildWithTag:kLicense] stringValue];
        _body = [[xml firstChildWithTag:kBody] stringValue];
        _os = [[xml firstChildWithTag:kOS] stringValue];
        _language = [[xml firstChildWithTag:kLanguage] stringValue];
        _recordTime = [[xml firstChildWithTag:kRecordTime] stringValue];
        _url = [NSURL URLWithString:[[xml firstChildWithTag:kURL] stringValue]];
        _homepageURL = [[xml firstChildWithTag:kHomepage] stringValue];
        _documentURL = [[xml firstChildWithTag:kDocument] stringValue];
        _downloadURL = [[xml firstChildWithTag:kDownload] stringValue];
        _logoURL = [[xml firstChildWithTag:kLogo] stringValue];
        _isFavorite = [[[xml firstChildWithTag:kFavorite] numberValue] boolValue];
        _tweetCount = [[[xml firstChildWithTag:kTweetCount] numberValue] intValue];
    }
    
    return self;
}

@end
