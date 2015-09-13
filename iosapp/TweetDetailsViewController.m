//
//  TweetDetailsViewController.m
//  iosapp
//
//  Created by chenhaoxiang on 10/28/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "TweetDetailsViewController.h"
#import "OSCTweet.h"
#import "TweetCell.h"
#import "UserDetailsViewController.h"
#import "ImageViewerController.h"
#import "TweetDetailsCell.h"
#import "UserDetailsViewController.h"
#import "Config.h"
#import "TweetsLikeListViewController.h"
#import "OSCUser.h"

#import <AFNetworking.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>
#import <MBProgressHUD.h>

@interface TweetDetailsViewController () <UIWebViewDelegate>

@property (nonatomic, strong) OSCTweet *tweet;
@property (nonatomic, assign) int64_t tweetID;

@property (nonatomic, assign) CGFloat webViewHeight;

@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation TweetDetailsViewController

- (instancetype)initWithTweetID:(int64_t)tweetID
{
    self = [super initWithCommentType:CommentTypeTweet andObjectID:tweetID];
    
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        
        _tweetID = tweetID;
    }
    
    return self;
}


- (void)viewDidLoad {
    self.needRefreshAnimation = NO;
    [super viewDidLoad];
    
    _HUD = [Utils createHUD];
    _HUD.userInteractionEnabled = NO;
    _HUD.dimBackground = YES;
    
    [self getTweetDetails];
}

- (void)getTweetDetails
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[Utils generateUserAgent] forHTTPHeaderField:@"User-Agent"];
//    manager.requestSerializer.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    manager.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
    
    [manager GET:[NSString stringWithFormat:@"%@%@?id=%lld", OSCAPI_PREFIX, OSCAPI_TWEET_DETAIL, _tweetID]
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseObject) {
             ONOXMLElement *tweetDetailsXML = [responseObject.rootElement firstChildWithTag:@"tweet"];
             
             _tweet = [[OSCTweet alloc] initWithXML:tweetDetailsXML];
             self.objectAuthorID = _tweet.authorID;
             _tweet.body = [NSString stringWithFormat:@"<style>a{color:#087221; text-decoration:none;}</style>\
                            <font size=\"3\"><strong>%@</strong></font>\
                            <br/>",
                            _tweet.body];
             
             if (_tweet.hasAnImage) {
                 _tweet.body = [NSString stringWithFormat:@"%@<a href='%@'>\
                                <img style='max-width:300px;\
                                margin-top:10px;\
                                margin-bottom:15px'\
                                src='%@'/>\
                                </a>", _tweet.body, _tweet.bigImgURL, _tweet.bigImgURL];
             }
             
             if (_tweet.attach.length) {
                 //有语音信息
                 
                 NSString *attachStr = [NSString stringWithFormat:@"<source src=\"%@?avthumb/mp3\" type=\"audio/mpeg\">", _tweet.attach];
                 _tweet.body = [NSString stringWithFormat:@"%@<br/><audio controls>%@</audio>", _tweet.body, attachStr];
             }
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.tableView reloadData];
             });
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [_HUD hide:YES];
         }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_HUD hide:YES];
    [super viewWillDisappear:animated];
}





#pragma mark - tableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0? 0 : 35;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    } else {
        NSString *title;
        if (self.allCount) {
            title = [NSString stringWithFormat:@"%d 条评论", self.allCount];
        } else {
            title = @"没有评论";
        }
        return title;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        [self.label setAttributedText:_tweet.likersDetailString];
        self.label.font = [UIFont systemFontOfSize:12];
        CGFloat height = [self.label sizeThatFits:CGSizeMake(tableView.frame.size.width - 16, MAXFLOAT)].height + 5;
        
        height += _webViewHeight;
        
        return height + 63;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        TweetDetailsCell *cell = [TweetDetailsCell new];
        
        if (_tweet) {
            [cell.portrait loadPortrait:_tweet.portraitURL];
            [cell.authorLabel setText:_tweet.author];
            
            [cell.portrait addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pushUserDetails)]];
            [cell.likeButton addTarget:self action:@selector(togglePraise) forControlEvents:UIControlEventTouchUpInside];
            [cell.likeListLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(PushToLikeList)]];
            
            [cell.likeListLabel setAttributedText:_tweet.likersDetailString];
            cell.likeListLabel.hidden = !_tweet.likeList.count;
            [cell.timeLabel setAttributedText:[Utils attributedTimeString:_tweet.pubDate]];
            if (_tweet.isLike) {
                [cell.likeButton setImage:[UIImage imageNamed:@"ic_liked"] forState:UIControlStateNormal];
            } else {
                [cell.likeButton setImage:[UIImage imageNamed:@"ic_unlike"] forState:UIControlStateNormal];
            }
            [cell.appclientLabel setAttributedText:[Utils getAppclient:_tweet.appclient]];
            cell.webView.delegate = self;
            [cell.webView loadHTMLString:_tweet.body baseURL:nil];
        }
        
        return cell;
    } else {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != 0) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return YES;
}


#pragma mark - 头像点击事件处理

- (void)pushUserDetails
{
    [self.navigationController pushViewController:[[UserDetailsViewController alloc] initWithUserID:_tweet.authorID] animated:YES];
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    CGFloat webViewHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight"] floatValue];
    if (_webViewHeight == webViewHeight) {return;}
    
    _webViewHeight = webViewHeight;
    //_webViewHeight = webView.scrollView.contentSize.height;
    [_HUD hide:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [Utils analysis:[request.URL absoluteString] andNavController:self.navigationController];
    return [request.URL.absoluteString isEqualToString:@"about:blank"];
}

#pragma mark - 跳转到点赞列表

- (void)PushToLikeList
{
    TweetsLikeListViewController *likeListCtl = [[TweetsLikeListViewController alloc] initWithtweetID:_tweet.tweetID];
    [self.navigationController pushViewController:likeListCtl animated:YES];
}

#pragma mark - 点赞功能
- (void)togglePraise
{
    [self toPraise:_tweet];
}

- (void)toPraise:(OSCTweet *)tweet
{
    NSString *postUrl;
    if (tweet.isLike) {
        postUrl = [NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_TWEET_UNLIKE];
    } else {
        postUrl = [NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_TWEET_LIKE];
    }

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[Utils generateUserAgent] forHTTPHeaderField:@"User-Agent"];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    manager.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
    [manager POST:postUrl
       parameters:@{
                    @"uid": @([Config getOwnID]),
                    @"tweetid": @(tweet.tweetID),
                    @"ownerOfTweet": @(tweet.authorID)
                    }
          success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseObject) {
              ONOXMLElement *resultXML = [responseObject.rootElement firstChildWithTag:@"result"];
              int errorCode = [[[resultXML firstChildWithTag: @"errorCode"] numberValue] intValue];
              NSString *errorMessage = [[resultXML firstChildWithTag:@"errorMessage"] stringValue];
              
              if (errorCode == 1) {
                  if (tweet.isLike) {
                      //取消点赞
                      for (OSCUser *user in tweet.likeList) {
                          if ([user.name isEqualToString:[Config getOwnUserName]]) {
                              [tweet.likeList removeObject:user];
                              break;
                          }
                      }
                      tweet.likeCount--;
                  } else {
                      //点赞
                      OSCUser *user = [OSCUser new];
                      user.userID = [Config getOwnID];
                      user.name = [Config getOwnUserName];
                      user.portraitURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", [Config getPortrait]]];
                      [tweet.likeList insertObject:user atIndex:0];
                      tweet.likeCount++;
                  }
                  tweet.isLike = !tweet.isLike;
                  tweet.likersDetailString = nil;
                  
#if 0
                  dispatch_async(dispatch_get_main_queue(), ^{
                      [self.tableView reloadData];
                  });
#else
                  [self.tableView beginUpdates];
                  [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                  [self.tableView endUpdates];
#endif
              } else {
                  MBProgressHUD *HUD = [Utils createHUD];
                  HUD.mode = MBProgressHUDModeCustomView;
                  
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                  HUD.labelText = [NSString stringWithFormat:@"错误：%@", errorMessage];
                  
                  [HUD hide:YES afterDelay:1];
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              MBProgressHUD *HUD = [Utils createHUD];
              HUD.mode = MBProgressHUDModeCustomView;
              
              HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
              HUD.detailsLabelText = error.userInfo[NSLocalizedDescriptionKey];
              
              [HUD hide:YES afterDelay:1];
          }];
}




@end
