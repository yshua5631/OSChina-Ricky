//
//  HomeController.h
//  iosapp
//
//  Created by 杨少华 on 15/9/11.
//  Copyright (c) 2015年 oschina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeController : UIViewController

{
    UIScrollView *_scrollView;
    UIImageView *_leftImageView;
    UIImageView *_centerImageView;
    UIImageView *_rightImageView;
    UIPageControl *_pageControl;
    UILabel *_label;
    NSMutableDictionary *_imageDataDic;//图片数据
    NSMutableDictionary *_imageKeyName;//根据key取名字
    NSMutableDictionary *_imageKeyPath;//根据key取图片路径
    int _currentImageIndex;//当前图片索引
    int _imageCount;//图片总数
}
@property(nonatomic,strong) UIScrollView *scrollView;
@property(nonatomic,strong) UIImageView *leftImageView;
@property(nonatomic,strong) UIImageView *centerImageView;
@property(nonatomic,strong) UIImageView *rightImageView;
@property(nonatomic,strong) UIPageControl *pageControl;
@property(nonatomic,strong) UILabel *label;
@property(nonatomic,strong) NSMutableDictionary *imageDataDic;//图片数据
@property(nonatomic) int currentImageIndex;//当前图片索引
@property(nonatomic) int _imageCount;//图片总数

- (instancetype)initWithTitle:(NSString *) title;
@end
