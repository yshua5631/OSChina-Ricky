//
//  HomeController.m
//  iosapp
//
//  Created by 杨少华 on 15/9/11.
//  Copyright (c) 2015年 oschina. All rights reserved.
//

#import "HomeController.h"
#import "UIImageView+WebCache.h"

#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 568
#define IMAGEVIEW_COUNT 3

@interface HomeController()<UIScrollViewDelegate>

@end

@implementation HomeController


- (instancetype)initWithTitle:(NSString *) title
{
    NSLog(@"研讨会主页初始化");
    self.title=title;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"研讨会主页加载");
    
    self.view.backgroundColor=[UIColor grayColor];
    
    // 研讨会视频轮播
    //加载数据
    [self loadImageData];
    //添加滚动控件
    [self addScrollView];
    //添加图片控件
    [self addImageViews];
    //添加分页控件
    [self addPageControl];
    //添加图片信息描述控件
    [self addLabel];
    //加载默认图片
    [self setDefaultImage];
    
    
}

#pragma mark 加载图片数据
-(void)loadImageData{
    //读取程序包路径中的资源文件
    NSString *path=[[NSBundle mainBundle] pathForResource:@"imageInfo" ofType:@"plist"];
    _imageDataDic=[NSMutableDictionary dictionaryWithContentsOfFile:path];
    _imageKeyName=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                   @"图片1",@"0",
                   @"图片2",@"1",
                   @"图片3",@"2",
                   @"图片4",@"3",
                   @"图片5",@"4",
                   @"图片6",@"5",
                   @"图片7",@"6",
                   @"图片8",@"7",
                   @"图片9",@"8",
                   nil];
    
    _imageKeyPath=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                   @"http://video.marykayintouch.com.cn/seminar/10001232.jpg",@"0",
                   @"http://video.marykayintouch.com.cn/seminar/10000232.jpg",@"1",
                   @"http://video.marykayintouch.com.cn/seminar/10015232.jpg",@"2",
                   @"http://video.marykayintouch.com.cn/seminar/10024232.jpg",@"3",
                   @"http://video.marykayintouch.com.cn/seminar/10022232.jpg",@"4",
                   @"http://video.marykayintouch.com.cn/seminar/10020232.jpg",@"5",
                   @"http://video.marykayintouch.com.cn/seminar/10019232.jpg",@"6",
                   @"http://video.marykayintouch.com.cn/seminar/10018232.jpg",@"7",
                   @"http://video.marykayintouch.com.cn/seminar/10016232.jpg",@"8",
                   nil];
    _imageCount=(int)_imageKeyName.count;
}

#pragma mark 添加控件
-(void)addScrollView{
    _scrollView=[[UIScrollView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:_scrollView];
    //设置代理
    _scrollView.delegate=self;
    //设置contentSize
    _scrollView.contentSize=CGSizeMake(IMAGEVIEW_COUNT*SCREEN_WIDTH, SCREEN_HEIGHT) ;
    //设置当前显示的位置为中间图片
    [_scrollView setContentOffset:CGPointMake(SCREEN_WIDTH, 0) animated:NO];
    //设置分页
    _scrollView.pagingEnabled=YES;
    //去掉滚动条
    _scrollView.showsHorizontalScrollIndicator=NO;
}

#pragma mark 添加图片三个控件
-(void)addImageViews{
    _leftImageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    _leftImageView.contentMode=UIViewContentModeScaleAspectFit;
    [_scrollView addSubview:_leftImageView];
    _centerImageView=[[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    _centerImageView.contentMode=UIViewContentModeScaleAspectFit;
    [_scrollView addSubview:_centerImageView];
    _rightImageView=[[UIImageView alloc]initWithFrame:CGRectMake(2*SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    _rightImageView.contentMode=UIViewContentModeScaleAspectFit;
    [_scrollView addSubview:_rightImageView];
    
}
#pragma mark 设置默认显示图片
-(void)setDefaultImage{
    //加载默认图片
    NSURL *lefturl=[NSURL URLWithString:_imageKeyPath[[NSString stringWithFormat:@"%d",_currentImageIndex-1]]];
    
    NSURL *centralurl=[NSURL URLWithString:_imageKeyPath[@"0"]];
    
    NSURL *righturl=[NSURL URLWithString:_imageKeyPath[@"1"]];
    
    
    [_leftImageView sd_setImageWithURL:lefturl completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    }];
    
    [_centerImageView sd_setImageWithURL:centralurl completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    }];
    
    [_leftImageView sd_setImageWithURL:righturl completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    }];
    
    _currentImageIndex=0;
    
    //设置当前页
    _pageControl.currentPage=_currentImageIndex;
    //NSString *imageName=[NSString stringWithFormat:@"%i.jpg",_currentImageIndex];
    _label.text=_imageKeyName[[NSString stringWithFormat:@"%d",_currentImageIndex]];
}

#pragma mark 添加分页控件
-(void)addPageControl{
    _pageControl=[[UIPageControl alloc]init];
    //注意此方法可以根据页数返回UIPageControl合适的大小
    CGSize size= [_pageControl sizeForNumberOfPages:_imageCount];
    _pageControl.bounds=CGRectMake(0, 0, size.width, size.height);
    _pageControl.center=CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT-100);
    //设置颜色
    _pageControl.pageIndicatorTintColor=[UIColor colorWithRed:193/255.0 green:219/255.0 blue:249/255.0 alpha:1];
    //设置当前页颜色
    _pageControl.currentPageIndicatorTintColor=[UIColor colorWithRed:0 green:150/255.0 blue:1 alpha:1];
    //设置总页数
    _pageControl.numberOfPages=_imageCount;
    
    [self.view addSubview:_pageControl];
}

#pragma mark 添加信息描述控件
-(void)addLabel{
    
    _label=[[UILabel alloc]initWithFrame:CGRectMake(0, 10, SCREEN_WIDTH,30)];
    _label.textAlignment=NSTextAlignmentCenter;
    _label.textColor=[UIColor colorWithRed:0 green:150/255.0 blue:1 alpha:1];
    
    [self.view addSubview:_label];
}

#pragma mark 滚动停止事件
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    //重新加载图片
    [self reloadImage];
    //移动到中间
    [_scrollView setContentOffset:CGPointMake(SCREEN_WIDTH, 0) animated:NO];
    //设置分页
    _pageControl.currentPage=_currentImageIndex;
    //设置描述
    //NSString *imageName=[NSString stringWithFormat:@"%i.jpg",_currentImageIndex];
    
    _label.text=_imageKeyName[[NSString stringWithFormat:@"%d",_currentImageIndex]];
}

#pragma mark 重新加载图片
-(void)reloadImage{
    int leftImageIndex,rightImageIndex;
    CGPoint offset=[_scrollView contentOffset];
    if (offset.x>SCREEN_WIDTH) { //向右滑动
        _currentImageIndex=(_currentImageIndex+1)%_imageCount;
    }else if(offset.x<SCREEN_WIDTH){ //向左滑动
        _currentImageIndex=(_currentImageIndex+_imageCount-1)%_imageCount;
    }
    
    [_centerImageView sd_setImageWithURL:[NSURL URLWithString:
                                          _imageKeyPath[[NSString stringWithFormat:@"%d",_currentImageIndex]]
                                          ] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    }];
    
    //重新设置左右图片
    leftImageIndex=(_currentImageIndex+_imageCount-1)%_imageCount;
    rightImageIndex=(_currentImageIndex+1)%_imageCount;
    
    
    [_leftImageView sd_setImageWithURL:[NSURL URLWithString:
                                        _imageKeyPath[[NSString stringWithFormat:@"%d",leftImageIndex]]
                                        ] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    }];
    
    [_rightImageView sd_setImageWithURL:[NSURL URLWithString:
                                         _imageKeyPath[[NSString stringWithFormat:@"%d",rightImageIndex]]
                                         ] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    }];
}

#pragma 缓存图片
-(UIImage *)getImageByKey:(int) key{
    
    NSString *imgKey=[NSString stringWithFormat:@"%d",  key];
    
    NSURL * url=[NSURL URLWithString: _imageKeyPath[imgKey]];
    
    SDImageCache *sd=[[SDWebImageManager sharedManager] imageCache];
    
    if (![[SDWebImageManager sharedManager] diskImageExistsForURL:url])
    {
        UIImage *img=[UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
        [sd storeImage:img forKey:imgKey toDisk:YES];
    }
    
    return [sd imageFromDiskCacheForKey:imgKey];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"研讨会主页WillAppear");
    
}

- (void) viewDidAppear:(BOOL)animated{
    
    //[super viewDidAppear:<#animated#>];
    //app尺寸，去掉状态栏
    CGRect r = [ UIScreen mainScreen ].applicationFrame;
    //r=0，20，320，460
    //屏幕尺寸
    //CGRect rx = [ UIScreen mainScreen ].bounds;
    //r=0，0，320，480
    //状态栏尺寸
    CGRect rect;
    rect = [[UIApplication sharedApplication] statusBarFrame];
    //iphone中获取屏幕分辨率的方法
    rect = [[UIScreen mainScreen] bounds];
    CGSize size = rect.size;
    CGFloat width = size.width;
    CGFloat height = size.height;
    NSLog(@"研讨会主页didAppear");
    
}

- (void) viewDidDisappear:(BOOL)animated{
    
    NSLog(@"研讨会主页DisAppear");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end