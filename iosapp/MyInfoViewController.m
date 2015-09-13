//
//  MyInfoViewController.m
//  iosapp
//
//  Created by ChanAetern on 12/10/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "MyInfoViewController.h"
#import "OSCAPI.h"
#import "OSCMyInfo.h"
#import "Config.h"
#import "Utils.h"
#import "SwipableViewController.h"
#import "FriendsViewController.h"
#import "FavoritesViewController.h"
#import "BlogsViewController.h"
#import "MessageCenter.h"
#import "LoginViewController.h"
#import "SearchViewController.h"
#import "MyBasicInfoViewController.h"

#import <AFNetworking.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <RESideMenu.h>
#import <MBProgressHUD.h>


@interface MyInfoViewController ()

@property (nonatomic, strong) OSCMyInfo *myInfo;
@property (nonatomic, readonly, assign) int64_t myID;
@property (nonatomic, strong) NSMutableArray *noticeCounts;

@property (nonatomic, strong) UIImageView *portrait;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *myQRCodeImageView;

@property (nonatomic, strong) UIButton *creditsBtn;
@property (nonatomic, strong) UIButton *collectionsBtn;
@property (nonatomic, strong) UIButton *followsBtn;
@property (nonatomic, strong) UIButton *fansBtn;

@property (nonatomic, assign) int badgeValue;

@end


@implementation MyInfoViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noticeUpdateHandler:) name:OSCAPI_USER_NOTICE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userRefreshHandler:)  name:@"userRefresh"     object:nil];
        
        _noticeCounts = [NSMutableArray arrayWithArray:@[@(0), @(0), @(0), @(0), @(0)]];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigationbar-search"] style:UIBarButtonItemStylePlain target:self action:@selector(pushSearchViewController)];
    self.navigationItem.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigationbar-sidebar"] style:UIBarButtonItemStylePlain target:self action:@selector(onClickMenuButton)];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.bounces = NO;
    self.navigationItem.title = @"我";
    self.view.backgroundColor = [UIColor colorWithHex:0xF5F5F5];
    
    UIView *Test=[[UIView alloc] initWithFrame:CGRectZero];
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
    [self refreshView];
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshView
{
    _myID = [Config getOwnID];
    if (_myID == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } else {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:[Utils generateUserAgent] forHTTPHeaderField:@"User-Agent"];
        manager.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
        [manager GET:[NSString stringWithFormat:@"%@%@?uid=%lld", OSCAPI_PREFIX, OSCAPI_MY_INFORMATION, _myID]
          parameters:nil
             success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDocument) {
                 ONOXMLElement *userXML = [responseDocument.rootElement firstChildWithTag:@"user"];
                 _myInfo = [[OSCMyInfo alloc] initWithXML:userXML];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.tableView reloadData];
                 });
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 MBProgressHUD *HUD = [Utils createHUD];
                 HUD.mode = MBProgressHUDModeCustomView;
                 HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                 HUD.labelText = @"网络异常，加载失败";
                 
                 [HUD hide:YES afterDelay:1];
             }];
    }
}



- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSArray *usersInformation = [Config getUsersInformation];
    
    UIImageView *header = [UIImageView new];
    header.userInteractionEnabled = YES;
    NSNumber *screenWidth = @([UIScreen mainScreen].bounds.size.width);
    NSString *imageName = @"user-background";
    if (screenWidth.intValue < 400) {
        imageName = [NSString stringWithFormat:@"%@-%@", imageName, screenWidth];;
    }
    header.image = [UIImage imageNamed:imageName];
    
    UIView *imageBackView = [UIView new];
    imageBackView.backgroundColor = [UIColor colorWithHex:0xEEEEEE];
    [imageBackView setCornerRadius:27];
    [header addSubview:imageBackView];
    
    _portrait = [UIImageView new];
    _portrait.contentMode = UIViewContentModeScaleAspectFit;
    [_portrait setCornerRadius:25];
    if (_myID == 0) {
        _portrait.image = [UIImage imageNamed:@"default-portrait"];
    } else {
        UIImage *portrait = [Config getPortrait];
        if (portrait == nil) {
            [_portrait sd_setImageWithURL:_myInfo.portraitURL
                         placeholderImage:[UIImage imageNamed:@"default-portrait"]
                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                [Config savePortrait:image];
                                                [[NSNotificationCenter defaultCenter] postNotificationName:@"userRefresh" object:@(YES)];
                                            }];
        } else {
            _portrait.image = portrait;
        }
    }
    _portrait.userInteractionEnabled = YES;
    [_portrait addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPortrait)]];
    [header addSubview:_portrait];
    
    UIImageView *genderImageView = [UIImageView new];
    genderImageView.hidden = YES;
    genderImageView.contentMode = UIViewContentModeScaleAspectFit;
    if (_myID == 0) {
        //
    } else {
        if (_myInfo.gender == 1) {
            [genderImageView setImage:[UIImage imageNamed:@"userinfo_icon_male"]];
            genderImageView.hidden = NO;
        } else if (_myInfo.gender == 2){
            [genderImageView setImage:[UIImage imageNamed:@"userinfo_icon_female"]];
            genderImageView.hidden = NO;
        }

    }
        [header addSubview:genderImageView];
    
    _nameLabel = [UILabel new];
    _nameLabel.textColor = [UIColor colorWithHex:0xEEEEEE];
    _nameLabel.font = [UIFont boldSystemFontOfSize:18];
    _nameLabel.text = usersInformation[0];
    [header addSubview:_nameLabel];
    
    UIImageView *QRCodeImageView = [UIImageView new];
    QRCodeImageView.image = [UIImage imageNamed:@"QR-Code"];
    QRCodeImageView.userInteractionEnabled = YES;
    [QRCodeImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapQRCodeImage)]];
    [header addSubview:QRCodeImageView];
    
    _creditsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _collectionsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _followsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _fansBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    UIView *line = [UIView new];
    line.backgroundColor = [UIColor colorWithHex:0x2bc157];
    [header addSubview:line];
    
    UIView *countView = [UIView new];
    [header addSubview:countView];

    void (^setButtonStyle)(UIButton *, NSString *) = ^(UIButton *button, NSString *title) {
        [button setTitleColor:[UIColor colorWithHex:0xEEEEEE] forState:UIControlStateNormal];
        button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont systemFontOfSize:15];
        [button setTitle:title forState:UIControlStateNormal];
        [countView addSubview:button];
    };
    
    setButtonStyle(_creditsBtn, [NSString stringWithFormat:@"积分\n%d", _myInfo.score]);
    setButtonStyle(_collectionsBtn, [NSString stringWithFormat:@"收藏\n%d", _myInfo.favoriteCount]);
    setButtonStyle(_followsBtn, [NSString stringWithFormat:@"关注\n%d", _myInfo.followersCount]);
    setButtonStyle(_fansBtn, [NSString stringWithFormat:@"粉丝\n%d", _myInfo.fansCount]);
    
    
    [_creditsBtn setTitle:[NSString stringWithFormat:@"积分\n%@", usersInformation[1]] forState:UIControlStateNormal];
    [_collectionsBtn setTitle:[NSString stringWithFormat:@"收藏\n%@", usersInformation[2]] forState:UIControlStateNormal];
    [_followsBtn setTitle:[NSString stringWithFormat:@"关注\n%@", usersInformation[3]] forState:UIControlStateNormal];
    [_fansBtn setTitle:[NSString stringWithFormat:@"粉丝\n%@", usersInformation[4]] forState:UIControlStateNormal];
    
    
    [_collectionsBtn addTarget:self action:@selector(pushFavoriteSVC) forControlEvents:UIControlEventTouchUpInside];
    [_followsBtn addTarget:self action:@selector(pushFriendsSVC:) forControlEvents:UIControlEventTouchUpInside];
    [_fansBtn addTarget:self action:@selector(pushFriendsSVC:) forControlEvents:UIControlEventTouchUpInside];
    
    for (UIView *view in header.subviews) {view.translatesAutoresizingMaskIntoConstraints = NO;}
    for (UIView *view in countView.subviews) {view.translatesAutoresizingMaskIntoConstraints = NO;}
    
    NSDictionary *views = NSDictionaryOfVariableBindings(imageBackView, _portrait, genderImageView, _nameLabel, _creditsBtn, _collectionsBtn, _followsBtn, _fansBtn, QRCodeImageView, countView, line);
    NSDictionary *metrics = @{@"width": @(tableView.frame.size.width / 4)};
    
    
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[_portrait(50)]-8-[_nameLabel]-10-[line(1)]-4-[countView(50)]|"
                                                                   options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[line]|" options:0 metrics:nil views:views]];
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_portrait(50)]" options:0 metrics:nil views:views]];
    
    ///背景白圈
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageBackView(54)]"
                                                                   options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[imageBackView(54)]" options:0 metrics:nil views:views]];
    [header addConstraint:[NSLayoutConstraint constraintWithItem:imageBackView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
                                                          toItem:_portrait attribute:NSLayoutAttributeCenterX multiplier:1 constant:27]];
    [header addConstraint:[NSLayoutConstraint constraintWithItem:imageBackView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
                                                          toItem:_portrait attribute:NSLayoutAttributeCenterY multiplier:1 constant:27]];
    
    ////男女区分图标
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[genderImageView(15)]"
                                                                   options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[genderImageView(15)]" options:0 metrics:nil views:views]];
    [header addConstraint:[NSLayoutConstraint constraintWithItem:_portrait attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
                                                          toItem:genderImageView attribute:NSLayoutAttributeCenterX multiplier:1 constant:7.5]];
    [header addConstraint:[NSLayoutConstraint constraintWithItem:_portrait attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
                                                          toItem:genderImageView attribute:NSLayoutAttributeCenterY multiplier:1 constant:7.5]];

    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[countView]|" options:0 metrics:nil views:views]];
    
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[QRCodeImageView]" options:0 metrics:nil views:views]];
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[QRCodeImageView]-15-|" options:0 metrics:nil views:views]];
    
    [countView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_creditsBtn(width)][_collectionsBtn(width)][_followsBtn(width)][_fansBtn(width)]|"
                                                                      options:NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom metrics:metrics views:views]];
    [countView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_creditsBtn]|" options:0 metrics:nil views:views]];
    
    
    if ([Config getOwnID] == 0) {
        line.hidden = YES;
        countView.hidden = YES;
        QRCodeImageView.hidden = YES;
    }
    
    return header;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell new];
    cell.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
    
    UIView *selectedBackground = [UIView new];
    selectedBackground.backgroundColor = [UIColor colorWithHex:0xF5FFFA];
    [cell setSelectedBackgroundView:selectedBackground];
    
    cell.backgroundColor = [UIColor colorWithHex:0xF9F9F9];
    cell.textLabel.text = @[@"消息", @"博客", @"团队"][indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@[@"me-message", @"me-blog", @"me-team"][indexPath.row]];
    
    if (indexPath.row == 0) {
        if (_badgeValue == 0) {
            cell.accessoryView = nil;
        } else {
            UILabel *accessoryBadge = [UILabel new];
            accessoryBadge.backgroundColor = [UIColor redColor];
            accessoryBadge.text = [@(_badgeValue) stringValue];
            accessoryBadge.textColor = [UIColor whiteColor];
            accessoryBadge.textAlignment = NSTextAlignmentCenter;
            accessoryBadge.layer.cornerRadius = 11;
            accessoryBadge.clipsToBounds = YES;
            
            CGFloat width = [accessoryBadge sizeThatFits:CGSizeMake(MAXFLOAT, 26)].width + 8;
            width = width > 26? width: 22;
            accessoryBadge.frame = CGRectMake(0, 0, width, 22);
            cell.accessoryView = accessoryBadge;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([Config getOwnID] == 0) {
        [self.navigationController pushViewController:[LoginViewController new] animated:YES];
        return;
    }
    
    switch (indexPath.row) {
        case 0: {
            _badgeValue = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            });
            self.navigationController.tabBarItem.badgeValue = nil;
            
            MessageCenter *messageCenterVC = [[MessageCenter alloc] initWithNoticeCounts:_noticeCounts];
            messageCenterVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:messageCenterVC animated:YES];
            
            break;
        }
        case 1: {
            BlogsViewController *blogsVC = [[BlogsViewController alloc] initWithUserID:_myID];
            blogsVC.navigationItem.title = @"我的博客";
            blogsVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:blogsVC animated:YES];
            break;
        }
        case 2: {
            MBProgressHUD *HUD = [Utils createHUD];
            HUD.mode = MBProgressHUDModeText;
            HUD.labelText = @"即将推出团队功能，敬请期待";
            [HUD hide:YES afterDelay:1];
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            break;
        }
        default: break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 160;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

- (void)pushFavoriteSVC
{
    SwipableViewController *favoritesSVC = [[SwipableViewController alloc] initWithTitle:@"收藏"
                                                                              andSubTitles:@[@"软件", @"话题", @"代码", @"博客", @"资讯"]
                                                                            andControllers:@[
                                                                                             [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeSoftware],
                                                                                             [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeTopic],
                                                                                             [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeCode],
                                                                                             [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeBlog],
                                                                                             [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeNews]
                                                                                             ]];
    favoritesSVC.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController pushViewController:favoritesSVC animated:YES];
}

- (void)pushFriendsSVC:(UIButton *)button
{
    SwipableViewController *friendsSVC = [[SwipableViewController alloc] initWithTitle:@"关注/粉丝"
                                                                            andSubTitles:@[@"关注", @"粉丝"]
                                                                          andControllers:@[
                                                                                           [[FriendsViewController alloc] initWithUserID:_myID andFriendsRelation:1],
                                                                                           [[FriendsViewController alloc] initWithUserID:_myID andFriendsRelation:0]
                                                                                           ]];
    if (button == _fansBtn) {[friendsSVC scrollToViewAtIndex:1];}
    
    friendsSVC.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController pushViewController:friendsSVC animated:YES];
}


- (void)onClickMenuButton
{
    [self.sideMenuViewController presentLeftMenuViewController];
}

- (void)pushSearchViewController
{
    [self.navigationController pushViewController:[SearchViewController new] animated:YES];
}


- (void)tapPortrait
{
    if (![Utils isNetworkExist]) {
        MBProgressHUD *HUD = [Utils createHUD];
        HUD.mode = MBProgressHUDModeText;
        HUD.labelText = @"网络无连接，请检查网络";
        
        [HUD hide:YES afterDelay:1];
    } else {
        if ([Config getOwnID] == 0) {
            [self.navigationController pushViewController:[LoginViewController new] animated:YES];
        } else {
            if (_myInfo) {
                [self.navigationController pushViewController:[[MyBasicInfoViewController alloc] initWithMyInformation:_myInfo] animated:YES];
            } else {
                [self.navigationController pushViewController:[MyBasicInfoViewController new] animated:YES];
            }
        }
    }
}


#pragma mark - 二维码相关

- (void)tapQRCodeImage
{
    MBProgressHUD *HUD = [Utils createHUD];
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.color = [UIColor whiteColor];
    
    HUD.labelText = @"扫一扫上面的二维码，加我为好友";
    HUD.labelFont = [UIFont systemFontOfSize:13];
    HUD.labelColor = [UIColor grayColor];
    HUD.customView = self.myQRCodeImageView;
    [HUD addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideHUD:)]];
}

- (void)hideHUD:(UIGestureRecognizer *)recognizer
{
    [(MBProgressHUD *)recognizer.view hide:YES];
}

- (UIImageView *)myQRCodeImageView
{
    if (!_myQRCodeImageView) {
        UIImage *myQRCode = [Utils createQRCodeFromString:[NSString stringWithFormat:@"http://my.oschina.net/u/%llu", [Config getOwnID]]];
        _myQRCodeImageView = [[UIImageView alloc] initWithImage:myQRCode];
    }
    
    return _myQRCodeImageView;
}


#pragma mark - 处理通知

- (void)noticeUpdateHandler:(NSNotification *)notification
{
    NSArray *noticeCounts = [notification object];
    
    __block int sumOfCount = 0;
    [noticeCounts enumerateObjectsUsingBlock:^(NSNumber *count, NSUInteger idx, BOOL *stop) {
        _noticeCounts[idx] = count;
        sumOfCount += [count intValue];
    }];
    
    _badgeValue = sumOfCount;
    if (_badgeValue) {
        self.navigationController.tabBarItem.badgeValue = [@(sumOfCount) stringValue];
    } else {
        self.navigationController.tabBarItem.badgeValue = nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    });
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:sumOfCount];
}

- (void)userRefreshHandler:(NSNotification *)notification
{
    [self refreshView];
}





@end
