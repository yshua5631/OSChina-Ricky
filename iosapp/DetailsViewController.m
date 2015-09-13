//
//  DetailsViewController.m
//  iosapp
//
//  Created by chenhaoxiang on 10/31/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "DetailsViewController.h"

#import <AFNetworking.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>
#import <MBProgressHUD.h>

#import "OSCAPI.h"
#import "OSCNews.h"
#import "OSCBlog.h"
#import "OSCPost.h"
#import "OSCSoftware.h"
#import "OSCNewsDetails.h"
#import "OSCBlogDetails.h"
#import "OSCPostDetails.h"
#import "OSCSoftwareDetails.h"
#import "Utils.h"
#import "Config.h"
#import "CommentsBottomBarViewController.h"
#import "SoftwareCommentsViewController.h"
#import "UMSocial.h"
#import "UIBarButtonItem+Badge.h"

#import <MBProgressHUD.h>


#define HTML_STYLE @"<style>\
                    #oschina_title {color: #000000; margin-bottom: 6px; font-weight:bold;}\
                    #oschina_title a {color:#0D6DA8;}\
                    #oschina_title img {vertical-align:middle; margin-right:6px;}\
                    #oschina_outline {color: #707070; font-size: 12px;}\
                    #oschina_outline a {color:#0D6DA8; text-decoration:none;}\
                    #oschina_software {color:#808080;font-size:12px}\
                    #oschina_body {font-size:16px; line-height:24px;}\
                    #oschina_body img {max-width: 100%;}\
                    #oschina_body table {max-width:100%;}\
                    #oschina_body pre {font-size:9pt; font-family:Courier New, Arial; border:1px solid #ddd; border-left:5px solid #6CE26C; background:#f6f6f6; padding:5px;}\
                    </style>"

#define HTML_BOTTOM @"<div style='margin-bottom:60px'/>"



@interface DetailsViewController () <UIWebViewDelegate, UIScrollViewDelegate, UIAlertViewDelegate>

@property (nonatomic, assign) CommentType commentType;
@property (nonatomic, assign) FavoriteType favoriteType;
@property (nonatomic, assign) int64_t objectID;
@property (nonatomic, assign) BOOL isStarred;

@property (nonatomic, strong) OSCNews *news;
@property (nonatomic, copy) NSString *detailsURL;
@property (nonatomic, readonly, assign) int commentCount;
@property (nonatomic, copy) NSString *webURL;
@property (nonatomic, copy) NSString *mURL;
@property (nonatomic, copy) NSString *objectTitle;
@property (nonatomic, strong) UIWebView *detailsView;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *softwareName;
@property (nonatomic, copy) NSString *digest;
@property (nonatomic, assign) SEL loadMethod;
@property (nonatomic, assign) Class detailsClass;

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation DetailsViewController

#pragma mark - 初始化方法

- (instancetype)initWithNews:(OSCNews *)news
{
    self = [super initWithModeSwitchButton:YES];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        
        _news = news;
        _objectID = news.newsID;
        
        switch (news.type) {
            case NewsTypeStandardNews:
                self.navigationItem.title = @"资讯详情";
                _detailsURL = [NSString stringWithFormat:@"%@%@?id=%lld", OSCAPI_PREFIX, OSCAPI_NEWS_DETAIL, news.newsID];
                _tag = @"news";
                _commentType = CommentTypeNews;
                _favoriteType = FavoriteTypeNews;
                _detailsClass = [OSCNewsDetails class];
                _loadMethod = @selector(loadNewsDetails:);
                break;
            case NewsTypeSoftWare:
                self.navigationItem.title = @"软件详情";
                _detailsURL = [NSString stringWithFormat:@"%@%@?ident=%@", OSCAPI_PREFIX, OSCAPI_SOFTWARE_DETAIL, news.attachment];
                _tag = @"software";
                _commentType = CommentTypeSoftware;
                _favoriteType = FavoriteTypeSoftware;
                _softwareName = news.attachment;
                _detailsClass = [OSCSoftwareDetails class];
                _loadMethod = @selector(loadSoftwareDetails:);
                break;
            case NewsTypeQA:
                self.navigationItem.title = @"帖子详情";
                _detailsURL = [NSString stringWithFormat:@"%@%@?id=%@", OSCAPI_PREFIX, OSCAPI_POST_DETAIL, news.attachment];
                _tag = @"post";
                _objectID = [news.attachment longLongValue];
                _commentType = CommentTypePost;
                _favoriteType = FavoriteTypeTopic;
                _detailsClass = [OSCPostDetails class];
                _loadMethod = @selector(loadPostDetails:);
                break;
            case NewsTypeBlog:
                self.navigationItem.title = @"博客详情";
                _detailsURL = [NSString stringWithFormat:@"%@%@?id=%@", OSCAPI_PREFIX, OSCAPI_BLOG_DETAIL, news.attachment];
                _tag = @"blog";
                _commentType = CommentTypeBlog;
                _favoriteType = FavoriteTypeBlog;
                _objectID = [news.attachment longLongValue];
                _detailsClass = [OSCBlogDetails class];
                _loadMethod = @selector(loadBlogDetails:);
                break;
            default:
                break;
        }
    }
    
    return self;
}

- (instancetype)initWithBlog:(OSCBlog *)blog
{
    self = [super initWithModeSwitchButton:YES];
    if (self) {
        _commentType = CommentTypeBlog;
        _favoriteType = FavoriteTypeBlog;
        _objectID = blog.blogID;
        
        self.hidesBottomBarWhenPushed = YES;
        self.navigationItem.title = @"博客详情";
        _detailsURL = [NSString stringWithFormat:@"%@%@?id=%lld", OSCAPI_PREFIX, OSCAPI_BLOG_DETAIL, blog.blogID];
        _tag = @"blog";
        _detailsClass = [OSCBlogDetails class];
        _loadMethod = @selector(loadBlogDetails:);
    }
    
    return self;
}

- (instancetype)initWithPost:(OSCPost *)post
{
    self = [super initWithModeSwitchButton:YES];
    if (!self) {return nil;}
    
    _commentType = CommentTypePost;
    _favoriteType = FavoriteTypeTopic;
    _objectID = post.postID;
    
    self.hidesBottomBarWhenPushed = YES;
    self.navigationItem.title = @"帖子详情";
    _detailsURL = [NSString stringWithFormat:@"%@%@?id=%lld", OSCAPI_PREFIX, OSCAPI_POST_DETAIL, post.postID];
    _tag = @"post";
    _detailsClass = [OSCPostDetails class];
    _loadMethod = @selector(loadPostDetails:);
    
    return self;
}

- (instancetype)initWithSoftware:(OSCSoftware *)software
{
    self = [super initWithModeSwitchButton:YES];
    if (!self) {return nil;}
    
    _commentType = CommentTypeSoftware;
    _favoriteType = FavoriteTypeSoftware;
    
    self.hidesBottomBarWhenPushed = YES;
    self.navigationItem.title = @"软件详情";
    _detailsURL = [NSString stringWithFormat:@"%@%@?ident=%@", OSCAPI_PREFIX, OSCAPI_SOFTWARE_DETAIL, software.url.absoluteString.lastPathComponent];
    _tag = @"software";
    _softwareName = software.name;
    _detailsClass = [OSCSoftwareDetails class];
    _loadMethod = @selector(loadSoftwareDetails:);
    
    return self;
}


#pragma mark - life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"刷新" style:UIBarButtonItemStyleDone target:self action:@selector(refresh)];
    
    // 资讯和软件详情没有“举报”选项
    if (_commentType == CommentTypeNews || _commentType == CommentTypeSoftware) {
        self.operationBar.items = [self.operationBar.items subarrayWithRange:NSMakeRange(0, 12)];
    }
    
    _detailsView = [UIWebView new];
    _detailsView.delegate = self;
    _detailsView.scrollView.delegate = self;
    _detailsView.scrollView.bounces = NO;
    _detailsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_detailsView];
    
    [self.view bringSubviewToFront:(UIView *)self.editingBar];
    
    
    NSDictionary *views = @{@"detailsView": _detailsView, @"bottomBar": self.editingBar};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[detailsView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[detailsView][bottomBar]"
                                                                      options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight
                                                                      metrics:nil views:views]];
    
    [self.editingBar.modeSwitchButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    // 添加等待动画
    _HUD = [Utils createHUD];
    _HUD.userInteractionEnabled = NO;
    
    _manager = [AFHTTPRequestOperationManager manager];
    [_manager.requestSerializer setValue:[Utils generateUserAgent] forHTTPHeaderField:@"User-Agent"];
    //_manager.requestSerializer.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    _manager.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
    [self fetchDetails];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_HUD hide:YES];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark -

- (void)setBlockForOperationBar
{
    __weak typeof(self) weakSelf = self;
    
    /********* 收藏 **********/
    
    self.operationBar.toggleStar = ^ {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:[Utils generateUserAgent] forHTTPHeaderField:@"User-Agent"];
        manager.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
        
        NSString *API = weakSelf.isStarred? OSCAPI_FAVORITE_DELETE: OSCAPI_FAVORITE_ADD;
        [manager POST:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, API]
           parameters:@{
                        @"uid":   @([Config getOwnID]),
                        @"objid": @(weakSelf.objectID),
                        @"type":  @(weakSelf.favoriteType)
                        }
              success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseObject) {
                  ONOXMLElement *result = [responseObject.rootElement firstChildWithTag:@"result"];
                  int errorCode = [[[result firstChildWithTag:@"errorCode"] numberValue] intValue];
                  NSString *errorMessage = [[result firstChildWithTag:@"errorMessage"] stringValue];
                  
                  MBProgressHUD *HUD = [Utils createHUD];
                  HUD.mode = MBProgressHUDModeCustomView;
                  
                  if (errorCode == 1) {
                      HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
                      HUD.labelText = weakSelf.isStarred? @"删除收藏成功": @"添加收藏成功";
                      weakSelf.isStarred = !weakSelf.isStarred;
                      weakSelf.operationBar.isStarred = weakSelf.isStarred;
                  } else {
                      HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                      HUD.labelText = [NSString stringWithFormat:@"错误：%@", errorMessage];
                  }
                 
                  [HUD hide:YES afterDelay:1];
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  MBProgressHUD *HUD = [Utils createHUD];
                  HUD.mode = MBProgressHUDModeCustomView;
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                  HUD.labelText = @"网络异常，操作失败";
                  
                  [HUD hide:YES afterDelay:1];
              }];
    };
    
    
    /********** 显示回复 ***********/
    
    self.operationBar.showComments = ^ {
        if (weakSelf.commentType == CommentTypeSoftware) {
            SoftwareCommentsViewController *softwareCommentsVC = [[SoftwareCommentsViewController alloc] initWithSoftwareID:weakSelf.objectID andSoftwareName:weakSelf.softwareName];
            [weakSelf.navigationController pushViewController:softwareCommentsVC animated:YES];
        } else {
            CommentsBottomBarViewController *commentsBVC = [[CommentsBottomBarViewController alloc] initWithCommentType:weakSelf.commentType andObjectID:weakSelf.objectID];
            [weakSelf.navigationController pushViewController:commentsBVC animated:YES];
        }
    };
    
    
    /********** 分享设置 ***********/
    
    self.operationBar.share = ^ {
        NSString *title = weakSelf.objectTitle;
        
        // 微信相关设置
        [UMSocialData defaultData].extConfig.wxMessageType = UMSocialWXMessageTypeWeb;
        [UMSocialData defaultData].extConfig.wechatSessionData.url = weakSelf.mURL;
        [UMSocialData defaultData].extConfig.wechatTimelineData.url = weakSelf.mURL;
        [UMSocialData defaultData].extConfig.title = title;
        
        // 手机QQ相关设置
        [UMSocialData defaultData].extConfig.qqData.qqMessageType = UMSocialQQMessageTypeDefault;
        [UMSocialData defaultData].extConfig.qqData.title = title;
        //[UMSocialData defaultData].extConfig.qqData.shareText = weakSelf.objectTitle;
        [UMSocialData defaultData].extConfig.qqData.url = weakSelf.mURL;
        
        // 新浪微博相关设置
        [[UMSocialData defaultData].extConfig.sinaData.urlResource setResourceType:UMSocialUrlResourceTypeDefault url:weakSelf.mURL];
        
        // 复制链接
#if 0
        UMSocialSnsPlatform *snsPlatform = [[UMSocialSnsPlatform alloc] initWithPlatformName:@"CustomPlatform"];
        snsPlatform.displayName = @"复制链接";
        snsPlatform.bigImageName = @"UMS_facebook_icon";
        snsPlatform.snsClickHandler = ^(UIViewController *presentingController, UMSocialControllerService *socialControllerService, BOOL isPresentInController){
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = weakSelf.mURL;
            
            MBProgressHUD *HUD = [Utils createHUD];
            HUD.mode = MBProgressHUDModeText;
            HUD.labelText = @"复制成功";
            
            [HUD hide:YES afterDelay:1];
        };
        
        [UMSocialConfig addSocialSnsPlatform:@[snsPlatform]];
        [UMSocialConfig setSnsPlatformNames:@[UMShareToWechatTimeline, UMShareToWechatSession, UMShareToQQ, UMShareToSina, @"CustomPlatform"]];
#endif
        
        [UMSocialSnsService presentSnsIconSheetView:weakSelf
                                             appKey:@"54c9a412fd98c5779c000752"
                                          shareText:[NSString stringWithFormat:@"%@...分享来自 %@", weakSelf.digest, weakSelf.mURL]
                                         shareImage:[UIImage imageNamed:@"logo"]
                                    shareToSnsNames:@[UMShareToWechatTimeline, UMShareToWechatSession, UMShareToQQ, UMShareToSina]
                                           delegate:nil];
    };
    
    
    /*********** 举报 ************/
    
    self.operationBar.report = ^ {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"举报"
                                                            message:[NSString stringWithFormat:@"链接地址：%@", weakSelf.webURL]
                                                           delegate:weakSelf
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"确定", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView textFieldAtIndex:0].placeholder = @"举报原因";
        [alertView show];
    };
}

- (NSString *)mURL
{
    if (_mURL) {
        return _mURL;
    } else {
        NSMutableString *strUrl = [NSMutableString stringWithFormat:@"%@", _webURL];
        if (_commentType == CommentTypeBlog) {
            strUrl = [NSMutableString stringWithFormat:@"http://m.oschina.net/blog/%lld", _objectID];
        } else {
            [strUrl replaceCharactersInRange:NSMakeRange(7, 3) withString:@"m"];
        }
        _mURL = [strUrl copy];
        return _mURL;
    }
}


- (void)fetchDetails
{
    [_manager GET:_detailsURL
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDocument) {
              ONOXMLElement *XML = [responseDocument.rootElement firstChildWithTag:_tag];
              
              id details = [[_detailsClass alloc] initWithXML:XML];
              _commentCount = [[[XML firstChildWithTag:@"commentCount"] numberValue] intValue];
              [self performSelector:_loadMethod withObject:details];
              
              self.operationBar.isStarred = _isStarred;
              
              UIBarButtonItem *commentsCountButton = self.operationBar.items[4];
              commentsCountButton.shouldHideBadgeAtZero = YES;
              commentsCountButton.badgeValue = [NSString stringWithFormat:@"%i", _commentCount];
              commentsCountButton.badgePadding = 1;
              commentsCountButton.badgeBGColor = [UIColor colorWithHex:0x24a83d];
              
              if (_commentType == CommentTypeSoftware) {_objectID = ((OSCSoftwareDetails *)details).softwareID;}
              
              [self setBlockForOperationBar];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              _HUD.mode = MBProgressHUDModeCustomView;
              _HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
              _HUD.labelText = @"网络异常，加载详情失败";
              
              [_HUD hide:YES afterDelay:1];
          }
     ];
}


- (void)refresh
{
    _manager.requestSerializer.cachePolicy = NSURLRequestUseProtocolCachePolicy;
    [self fetchDetails];
}




- (void)loadNewsDetails:(OSCNewsDetails *)newsDetails
{
    newsDetails.title = [Utils escapeHTML:newsDetails.title];
    
    NSString *authorStr = [NSString stringWithFormat:@"<a href='http://my.oschina.net/u/%lld'>%@</a> 发布于 %@", newsDetails.authorID, newsDetails.author, [Utils intervalSinceNow:newsDetails.pubDate]];
    
    NSString *software = @"";
    if ([newsDetails.softwareName isEqualToString:@""] == NO) {
        software = [NSString stringWithFormat:@"<div id='oschina_software' style='margin-top:8px;color:#FF0000;font-size:14px;font-weight:bold'>更多关于:&nbsp;<a href='%@'>%@</a>&nbsp;的详细信息</div>", newsDetails.softwareLink, newsDetails.softwareName];
    }
    
    NSString *html = [NSString stringWithFormat:@"<body style='background-color:#EBEBF3'>%@<div id='oschina_title'>%@</div><div id='oschina_outline'>%@</div><hr/><div id='oschina_body'>%@</div>%@%@%@</body>", HTML_STYLE, newsDetails.title, authorStr, newsDetails.body, software, [Utils generateRelativeNewsString:newsDetails.relatives], HTML_BOTTOM];
    
    [self.detailsView loadHTMLString:html baseURL:nil];
    _isStarred = newsDetails.isFavorite;
    _webURL = [newsDetails.url absoluteString];
    _objectTitle = newsDetails.title;
    
    NSString *trimmedHTML = [Utils deleteHTMLTag:newsDetails.body];
    NSInteger length = trimmedHTML.length < 60 ? trimmedHTML.length : 60;
    _digest = [[Utils deleteHTMLTag:newsDetails.body] substringToIndex:length];
}

- (void)loadBlogDetails:(OSCBlogDetails *)blogDetails
{
    blogDetails.title = [Utils escapeHTML:blogDetails.title];
    
    NSString *authorStr = [NSString stringWithFormat:@"<a href='http://my.oschina.net/u/%lld'>%@</a>&nbsp;发表于&nbsp;%@", blogDetails.authorID, blogDetails.author,  [Utils intervalSinceNow:blogDetails.pubDate]];
    NSString *html = [NSString stringWithFormat:@"<body style='background-color:#EBEBF3'>%@<div id='oschina_title'>%@</div><div id='oschina_outline'>%@</div><hr/><div id='oschina_body'>%@</div>%@</body>",HTML_STYLE, blogDetails.title, authorStr, blogDetails.body, HTML_BOTTOM];
    
    [self.detailsView loadHTMLString:html baseURL:nil];
    _isStarred = blogDetails.isFavorite;
    _webURL = [blogDetails.url absoluteString];
    _objectTitle = blogDetails.title;
    
    NSString *trimmedHTML = [Utils deleteHTMLTag:blogDetails.body];
    NSInteger length = trimmedHTML.length < 60 ? trimmedHTML.length : 60;
    _digest = [[Utils deleteHTMLTag:blogDetails.body] substringToIndex:length];
}

- (void)loadPostDetails:(OSCPostDetails *)postDetails
{
    postDetails.title = [Utils escapeHTML:postDetails.title];
    
    NSString *authorStr = [NSString stringWithFormat:@"<a href='http://my.oschina.net/u/%lld'>%@</a> 发布于 %@", postDetails.authorID, postDetails.author, [Utils intervalSinceNow:postDetails.pubDate]];
    
    NSString *html = [NSString stringWithFormat:@"<body style='background-color:#EBEBF3;'>%@<div id='oschina_title'>%@</div><div id='oschina_outline'>%@</div><hr/><div id='oschina_body'>%@</div>%@%@</body>",HTML_STYLE, postDetails.title, authorStr, postDetails.body, [Utils GenerateTags:postDetails.tags], HTML_BOTTOM];
    
    [self.detailsView loadHTMLString:html baseURL:nil];
    _isStarred = postDetails.isFavorite;
    _webURL = [postDetails.url absoluteString];
    _commentCount = postDetails.answerCount;
    _objectTitle = postDetails.title;
    
    NSString *trimmedHTML = [Utils deleteHTMLTag:postDetails.body];
    NSInteger length = trimmedHTML.length < 60 ? trimmedHTML.length : 60;
    _digest = [[Utils deleteHTMLTag:postDetails.body] substringToIndex:length];
}

- (void)loadSoftwareDetails:(OSCSoftwareDetails *)softwareDetails
{
    softwareDetails.title = [Utils escapeHTML:softwareDetails.title];
    
    NSString *titleStr = [NSString stringWithFormat:@"%@ %@", softwareDetails.extensionTitle, softwareDetails.title];
    
    NSString *tail = [NSString stringWithFormat:@"<div><table><tr><td style='font-weight:bold'>授权协议:&nbsp;</td><td>%@</td></tr><tr><td style='font-weight:bold'>开发语言:</td><td>%@</td></tr><tr><td style='font-weight:bold'>操作系统:</td><td>%@</td></tr><tr><td style='font-weight:bold'>收录时间:</td><td>%@</td></tr></table></div>", softwareDetails.license, softwareDetails.language, softwareDetails.os, softwareDetails.recordTime];
    
    NSString *html = [NSString stringWithFormat:@"<body style='background-color:#EBEBF3'>%@<div id='oschina_title'><img src='%@' width='34' height='34'/>%@</div><hr/><div id='oschina_body'>%@</div><div>%@</div>%@%@</body>", HTML_STYLE, softwareDetails.logoURL, titleStr, softwareDetails.body, tail, [self createButtonsWithHomepageURL:softwareDetails.homepageURL andDocumentURL:softwareDetails.documentURL andDownloadURL:softwareDetails.downloadURL], HTML_BOTTOM];
    
    [self.detailsView loadHTMLString:html baseURL:nil];
    _isStarred = softwareDetails.isFavorite;
    _webURL = [softwareDetails.url absoluteString];
    
    _commentCount = softwareDetails.tweetCount;
    _objectTitle = titleStr;
    
    NSString *trimmedHTML = [Utils deleteHTMLTag:softwareDetails.body];
    NSInteger length = trimmedHTML.length < 60 ? trimmedHTML.length : 60;
    _digest = [[Utils deleteHTMLTag:softwareDetails.body] substringToIndex:length];
}

- (NSString *)createButtonsWithHomepageURL:(NSString *)homepageURL andDocumentURL:(NSString *)documentURL andDownloadURL:(NSString *)downloadURL
{
    NSString *strHomePage = @"";
    NSString *strDocument = @"";
    NSString *strDownload = @"";
    
    if ([homepageURL isEqualToString:@""] == NO) {
        strHomePage = [NSString stringWithFormat:@"<a href=%@><input type='button' value='软件首页' style='font-size:14px;'/></a>", homepageURL];
    }
    if ([documentURL isEqualToString:@""] == NO) {
        strDocument = [NSString stringWithFormat:@"<a href=%@><input type='button' value='软件文档' style='font-size:14px;'/></a>", documentURL];
    }
    if ([downloadURL isEqualToString:@""] == NO) {
        strDownload = [NSString stringWithFormat:@"<a href=%@><input type='button' value='软件下载' style='font-size:14px;'/></a>", downloadURL];
    }
    
    return [NSString stringWithFormat:@"<p>%@&nbsp;&nbsp;%@&nbsp;&nbsp;%@</p>", strHomePage, strDocument, strDownload];
}



#pragma mark - 发表评论

- (void)sendContent
{
    MBProgressHUD *HUD = [Utils createHUD];
    HUD.labelText = @"评论发送中";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[Utils generateUserAgent] forHTTPHeaderField:@"User-Agent"];
    manager.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
    
    NSString *URL;
    NSDictionary *parameters;
    NSString *content = [Utils convertRichTextToRawText:self.editingBar.editView];
    
    if (_commentType == CommentTypeSoftware) {
        URL = [NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_TWEET_PUB];
        parameters = @{
                       @"uid": @([Config getOwnID]),
                       @"msg": [content stringByAppendingString:[NSString stringWithFormat:@" #%@#", _softwareName]]
                       };
    } else if (_commentType == CommentTypeBlog) {
        URL = [NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_BLOGCOMMENT_PUB];
        parameters = @{
                       @"blog": @(_objectID),
                       @"uid": @([Config getOwnID]),
                       @"content": content,
                       @"reply_id": @(0),
                       @"objuid": @(0)
                       };
    } else {
        URL = [NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_COMMENT_PUB];
        parameters = @{
                       @"catalog": @(_commentType),
                       @"id": @(_objectID),
                       @"uid": @([Config getOwnID]),
                       @"content": content,
                       @"isPostToMyZone": @(0)
                       };
    }
    
    [manager POST:URL
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDocument) {
              ONOXMLElement *result = [responseDocument.rootElement firstChildWithTag:@"result"];
              int errorCode = [[[result firstChildWithTag:@"errorCode"] numberValue] intValue];
              NSString *errorMessage = [[result firstChildWithTag:@"errorMessage"] stringValue];
              
              HUD.mode = MBProgressHUDModeCustomView;
              
              if (errorCode == 1) {
                  self.editingBar.editView.text = @"";
                  [self updateInputBarHeight];
                  
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
                  HUD.labelText = @"评论发表成功";
              } else {
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                  HUD.labelText = [NSString stringWithFormat:@"错误：%@", errorMessage];
              }
              
              [HUD hide:YES afterDelay:2];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              HUD.mode = MBProgressHUDModeCustomView;
              HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
              HUD.labelText = @"网络异常，动弹发送失败";
              
              [HUD hide:YES afterDelay:2];
          }];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView != self.editingBar.editView) {
        [self.editingBar.editView resignFirstResponder];
        [self hideEmojiPageView];
    }
}



#pragma mark - 浏览器链接处理

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [Utils analysis:[request.URL absoluteString] andNavController:self.navigationController];
    return [request.URL.absoluteString isEqualToString:@"about:blank"];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_HUD hide:YES];
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex]) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:[Utils generateUserAgent] forHTTPHeaderField:@"User-Agent"];
        manager.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
        
        [manager POST:@"http://www.oschina.net/action/communityManage/report"
           parameters:@{
                        @"memo":        [alertView textFieldAtIndex:0].text.length == 0? @"其他原因": [alertView textFieldAtIndex:0].text,
                        @"obj_id":      @(_objectID),
                        @"obj_type":    @"4",
                        @"url":         _webURL
                        }
              success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseObject) {
                  MBProgressHUD *HUD = [Utils createHUD];
                  HUD.mode = MBProgressHUDModeCustomView;
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
                  HUD.labelText = @"举报成功";
                  
                  [HUD hide:YES afterDelay:1];
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  MBProgressHUD *HUD = [Utils createHUD];
                  HUD.mode = MBProgressHUDModeCustomView;
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                  HUD.labelText = @"网络异常，操作失败";
                  
                  [HUD hide:YES afterDelay:1];
              }];
    }
}





@end
