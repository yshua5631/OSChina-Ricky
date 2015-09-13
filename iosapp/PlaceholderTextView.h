//
//  PlaceholderTextView.h
//  iosapp
//
//  Created by chenhaoxiang on 3/3/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlaceholderTextView : UITextView

@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) UIFont   *placeholderFont;

- (instancetype)initWithPlaceholder:(NSString *)placeholder;
- (void)checkShouldHidePlaceholder;

@end
