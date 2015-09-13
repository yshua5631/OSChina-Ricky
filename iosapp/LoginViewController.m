//
//  LoginViewController.m
//  iosapp
//
//  Created by chenhaoxiang on 11/4/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "LoginViewController.h"
#import "UserDetailsViewController.h"
#import "OSCAPI.h"
#import "OSCUser.h"
#import "Utils.h"
#import "Config.h"
#import "OSCThread.h"
#import "MyInfoViewController.h"

#import <AFNetworking.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>
#import <ReactiveCocoa.h>
#import <MBProgressHUD.h>
#import <RESideMenu.h>
#import <TTTAttributedLabel.h>
#import <CoreText/CoreText.h>

@interface LoginViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate, TTTAttributedLabelDelegate>

@property (nonatomic, strong) UITextField *accountField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UIButton *loginButton;

@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) TTTAttributedLabel *registerInfo;

@end

@implementation LoginViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"登录";
    self.view.backgroundColor = [UIColor themeColor];
    
    [self initSubviews];
    [self setLayout];
    
    NSArray *accountAndPassword = [Config getOwnAccountAndPassword];
    _accountField.text = accountAndPassword? accountAndPassword[0] : @"";
    _passwordField.text = accountAndPassword? accountAndPassword[1] : @"";
    
    RACSignal *valid = [RACSignal combineLatest:@[_accountField.rac_textSignal, _passwordField.rac_textSignal]
                                         reduce:^(NSString *account, NSString *password) {
                                             return @(account.length > 0 && password.length > 0);
                                         }];
    RAC(_loginButton, enabled) = valid;
    RAC(_loginButton, alpha) = [valid map:^(NSNumber *b) {
        return b.boolValue ? @1: @0.4;
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_HUD hide:YES];
}



#pragma mark - about subviews
- (void)initSubviews
{
    _accountField = [UITextField new];
    _accountField.placeholder = @"Email";
    _accountField.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _accountField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _accountField.keyboardType = UIKeyboardTypeEmailAddress;
    _accountField.delegate = self;
    _accountField.returnKeyType = UIReturnKeyNext;
    _accountField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _accountField.enablesReturnKeyAutomatically = YES;
    
    self.passwordField = [UITextField new];
    _passwordField.placeholder = @"Password";
    _passwordField.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _passwordField.secureTextEntry = YES;
    _passwordField.delegate = self;
    _passwordField.returnKeyType = UIReturnKeyDone;
    _passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _passwordField.enablesReturnKeyAutomatically = YES;
    
    [_accountField addTarget:self action:@selector(returnOnKeyboard:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_passwordField addTarget:self action:@selector(returnOnKeyboard:) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [self.view addSubview: _accountField];
    [self.view addSubview: _passwordField];
    
    _loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _loginButton.titleLabel.font = [UIFont systemFontOfSize:17];
    _loginButton.backgroundColor = [UIColor colorWithHex:0x15A230];
    [_loginButton setCornerRadius:20];
    [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
    [_loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview: _loginButton];
    
    _registerInfo = [TTTAttributedLabel new];
    _registerInfo.delegate = self;
    _registerInfo.numberOfLines = 0;
    _registerInfo.lineBreakMode = NSLineBreakByWordWrapping;
    _registerInfo.backgroundColor = [UIColor themeColor];
    _registerInfo.font = [UIFont systemFontOfSize:14];
    NSString *info = @"您可以在 https://www.oschina.net 上免费注册账号";
    _registerInfo.text = info;
    NSRange range = [info rangeOfString:@"https://www.oschina.net"];
    _registerInfo.linkAttributes = @{
                                     (NSString *)kCTForegroundColorAttributeName:[UIColor colorWithHex:0x15A230]
                                     };
    [_registerInfo addLinkToURL:[NSURL URLWithString:@"https://www.oschina.net/home/reg"] withRange:range];
    [self.view addSubview:_registerInfo];
    
    //添加手势，点击屏幕其他区域关闭键盘的操作
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hidenKeyboard)];
    gesture.numberOfTapsRequired = 1;
    gesture.delegate = self;
    [self.view addGestureRecognizer:gesture];
}

- (void)setLayout
{
    UIImageView *email = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login-email"]];
    email.contentMode = UIViewContentModeScaleAspectFill;
    
    UIImageView *password = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login-password"]];
    password.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.view addSubview:email];
    [self.view addSubview:password];
    
    for (UIView *view in [self.view subviews]) { view.translatesAutoresizingMaskIntoConstraints = NO;}
    
    NSDictionary *views = NSDictionaryOfVariableBindings(email, password, _accountField, _passwordField, _loginButton, _registerInfo);
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view    attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
                                                             toItem:_loginButton attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                                             toItem:_loginButton attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[email(20)]-20-[password(20)]-30-[_loginButton(40)]"
                                                                      options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-20-[_loginButton]-20-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_loginButton]-20-[_registerInfo(30)]"
                                                                      options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight
                                                                      metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-30-[email(20)]-[_accountField]-30-|"     options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-30-[password(20)]-[_passwordField]-30-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (![_accountField isFirstResponder] && ![_passwordField isFirstResponder]) {
        return NO;
    }
    return YES;
}


#pragma mark - 键盘操作

- (void)hidenKeyboard
{
    [_accountField resignFirstResponder];
    [_passwordField resignFirstResponder];
}

- (void)returnOnKeyboard:(UITextField *)sender
{
    if (sender == _accountField) {
        [_passwordField becomeFirstResponder];
    } else if (sender == _passwordField) {
        [self hidenKeyboard];
        if (_loginButton.enabled) {
            [self login];
        }
    }
}

- (void)login
{
    _HUD = [Utils createHUD];
    _HUD.labelText = @"正在登录";
    _HUD.userInteractionEnabled = NO;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[Utils generateUserAgent] forHTTPHeaderField:@"User-Agent"];
    manager.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
    [manager POST:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_LOGIN_VALIDATE]
       parameters:@{@"username" : _accountField.text, @"pwd" : _passwordField.text, @"keep_login" : @(1)}
          success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseObject) {
              ONOXMLElement *result = [responseObject.rootElement firstChildWithTag:@"result"];
              ONOXMLElement *userXML = [responseObject.rootElement firstChildWithTag:@"user"];
              
              NSInteger errorCode = [[[result firstChildWithTag:@"errorCode"] numberValue] integerValue];
              if (!errorCode) {
                  NSString *errorMessage = [[result firstChildWithTag:@"errorMessage"] stringValue];
                  
                  _HUD.mode = MBProgressHUDModeCustomView;
                  _HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                  _HUD.labelText = [NSString stringWithFormat:@"错误：%@", errorMessage];
                  [_HUD hide:YES afterDelay:1];
                  
                  return;
              }
              
              OSCUser *user = [[OSCUser alloc] initWithXML:userXML];
              [Config saveOwnAccount:_accountField.text andPassword:_passwordField.text];
              [Config saveOwnID:user.userID userName:user.name score:user.score favoriteCount:user.favoriteCount fansCount:user.fansCount andFollowerCount:user.followersCount];
              [OSCThread startPollingNotice];
              
              [self saveCookies];
              
              [[NSNotificationCenter defaultCenter] postNotificationName:@"userRefresh" object:@(YES)];
              [self.navigationController popViewControllerAnimated:YES];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              _HUD.mode = MBProgressHUDModeCustomView;
              _HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
              _HUD.labelText = @"网络异常，登录失败";
              
              [_HUD hide:YES afterDelay:1];
          }
     ];
}



/*** 不知为何有时退出应用后，cookie不保存，所以这里手动保存cookie ***/

- (void)saveCookies
{
    NSData *cookiesData = [NSKeyedArchiver archivedDataWithRootObject: [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: cookiesData forKey: @"sessionCookies"];
    [defaults synchronize];
    
}



#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}



@end
