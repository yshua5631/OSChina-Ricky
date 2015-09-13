//
//  OSCActivity.h
//  iosapp
//
//  Created by chenhaoxiang on 1/25/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "OSCBaseObject.h"

@interface OSCActivity : OSCBaseObject

@property (nonatomic, readonly, assign)   int64_t     activityID;
@property (nonatomic, readonly, strong)   NSURL      *coverURL;
@property (nonatomic, readonly, strong)   NSURL      *url;
@property (nonatomic, readonly, copy)     NSString   *title;
@property (nonatomic, readonly, copy)     NSString   *startTime;
@property (nonatomic, readonly, copy)     NSString   *endTime;
@property (nonatomic, readonly, copy)     NSString   *createTime;
@property (nonatomic, readonly, copy)     NSString   *location;
@property (nonatomic, readonly, copy)     NSString   *city;
@property (nonatomic, readonly, assign)   int         status;
@property (nonatomic, readonly, assign)   int         applyStatus;

@end
