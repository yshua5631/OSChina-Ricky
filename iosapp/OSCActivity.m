//
//  OSCActivity.m
//  iosapp
//
//  Created by chenhaoxiang on 1/25/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "OSCActivity.h"

@implementation OSCActivity

- (instancetype)initWithXML:(ONOXMLElement *)xml
{
    self = [super init];
    
    if (self) {
        _activityID  = [[[xml firstChildWithTag:@"id"] numberValue] longLongValue];
        _coverURL    = [NSURL URLWithString:[[xml firstChildWithTag:@"cover"] stringValue]];
        _url         = [NSURL URLWithString:[[xml firstChildWithTag:@"url"]   stringValue]];
        _title       = [[xml firstChildWithTag:@"title"] stringValue];
        _startTime   = [[xml firstChildWithTag:@"startTime"] stringValue];
        _endTime     = [[xml firstChildWithTag:@"endTIme"] stringValue];
        _createTime  = [[xml firstChildWithTag:@"createTime"] stringValue];
        _location    = [[xml firstChildWithTag:@"spot"] stringValue];
        _city        = [[xml firstChildWithTag:@"city"] stringValue];
        _status      = [[[xml firstChildWithTag:@"status"] numberValue] intValue];
        _applyStatus = [[[xml firstChildWithTag:@"applyStatus"] numberValue] intValue];
    }
    
    return self;
}


- (BOOL)isEqual:(id)object
{
    if ([self class] == [object class]) {
        return _activityID == ((OSCActivity *)object).activityID;
    }
    
    return NO;
}


@end
