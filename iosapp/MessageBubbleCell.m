//
//  MessageBubbleCell.m
//  iosapp
//
//  Created by ChanAetern on 2/12/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "MessageBubbleCell.h"
#import "Utils.h"

static const int othersBubbleColor = 0x15A230;
static const int myBubbleColor     = 0xC7C7C7;

@interface MessageBubbleCell ()

@property (nonatomic, assign) BOOL isMine;

@property (nonatomic, strong) UILabel     *messageLabel;

@property (nonatomic, strong) UIImageView *bubbleImageView;
@property (nonatomic, strong) NSLayoutConstraint *bubbleWidthConstraint;

@end

@implementation MessageBubbleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        if (reuseIdentifier == kMessageBubbleMe) {
            _isMine = YES;
        } else {
            _isMine = NO;
        }
        
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor themeColor];
        
        [self initSubviews];
        [self setLayout];
        
        UIView *selectedBackground = [UIView new];
        selectedBackground.backgroundColor = [UIColor colorWithHex:0xF5FFFA];
        [self setSelectedBackgroundView:selectedBackground];
    }
    
    return self;
}

- (void)initSubviews
{
    // 头像
    _portrait = [UIImageView new];
    _portrait.contentMode = UIViewContentModeScaleAspectFit;
    [_portrait setCornerRadius:18];
    _portrait.userInteractionEnabled = YES;
    [self.contentView addSubview:_portrait];
    
    
    // 内容
    _messageLabel = [UILabel new];
    _messageLabel.font = [UIFont systemFontOfSize:15];
    _messageLabel.numberOfLines = 0;
    _messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    
    // 气泡
    UIImage *bubbleImage = [UIImage imageNamed:@"bubble"];
    if (_isMine) {
        bubbleImage = [bubbleImage imageMaskedWithColor:[UIColor colorWithHex:myBubbleColor]];
        _messageLabel.backgroundColor = [UIColor colorWithHex:myBubbleColor];
    } else {
        bubbleImage = [bubbleImage imageMaskedWithColor:[UIColor colorWithHex:othersBubbleColor]];
        bubbleImage = [self jsq_horizontallyFlippedImageFromImage:bubbleImage];
        
        _messageLabel.textColor = [UIColor colorWithHex:0xE1E1E1];
        _messageLabel.backgroundColor = [UIColor colorWithHex:othersBubbleColor];
    }
    bubbleImage = [bubbleImage resizableImageWithCapInsets:[self jsq_centerPointEdgeInsetsForImageSize:bubbleImage.size]
                                              resizingMode:UIImageResizingModeStretch];
    
    _bubbleImageView = [UIImageView new];
    _bubbleImageView.image = bubbleImage;
    [self.contentView addSubview:_bubbleImageView];
    [self.contentView addSubview:_messageLabel];
}

- (void)setLayout
{
    for (UIView *view in self.contentView.subviews) {view.translatesAutoresizingMaskIntoConstraints = NO;}
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_portrait, _bubbleImageView);
    
    if (_isMine) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_bubbleImageView]-8-[_portrait(36)]-8-|"
                                                                                 options:NSLayoutFormatAlignAllBottom metrics:nil views:views]];
    } else {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-8-[_portrait(36)]-8-[_bubbleImageView]"
                                                                                 options:NSLayoutFormatAlignAllBottom metrics:nil views:views]];
    }
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_portrait(36)]" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[_bubbleImageView]-8-|" options:0 metrics:nil views:views]];
    
    
    CGFloat constantLeft, constantRight;
    if (_isMine) {constantLeft = -10.0; constantRight = 15.0;}
    else {constantLeft = -15.0; constantRight = 10.0;}
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_bubbleImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
                                                                    toItem:_messageLabel    attribute:NSLayoutAttributeBottom multiplier:1.0 constant:10.0]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_bubbleImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                                                    toItem:_messageLabel    attribute:NSLayoutAttributeTop multiplier:1.0 constant:-10.0]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_bubbleImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
                                                                    toItem:_messageLabel    attribute:NSLayoutAttributeLeft multiplier:1.0 constant:constantLeft]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_bubbleImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
                                                                    toItem:_messageLabel    attribute:NSLayoutAttributeRight multiplier:1.0 constant:constantRight]];
    
    
    _bubbleWidthConstraint = [NSLayoutConstraint constraintWithItem:_bubbleImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                             toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:25];
    
    [self.contentView addConstraint:_bubbleWidthConstraint];
}


- (UIImage *)jsq_horizontallyFlippedImageFromImage:(UIImage *)image
{
    return [UIImage imageWithCGImage:image.CGImage
                               scale:image.scale
                         orientation:UIImageOrientationUpMirrored];
}


- (UIEdgeInsets)jsq_centerPointEdgeInsetsForImageSize:(CGSize)bubbleImageSize
{
    CGPoint center = CGPointMake(bubbleImageSize.width / 2.0f, bubbleImageSize.height / 2.0f);
    return UIEdgeInsetsMake(center.y, center.x, center.y, center.x);
}


- (void)setContent:(NSString *)content andPortrait:(NSURL *)portraitURL
{
    _messageLabel.text = content;
    [_portrait loadPortrait:portraitURL];
    
    
    CGFloat bubbleWidth = [_messageLabel sizeThatFits:CGSizeMake(self.contentView.frame.size.width-85, MAXFLOAT)].width;
    
    _bubbleWidthConstraint.constant = bubbleWidth + 25;
    [self.contentView setNeedsUpdateConstraints];
    [self.contentView layoutIfNeeded];
}

#pragma mark - 处理长按操作

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return _canPerformAction(self, action);
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)copyText:(id)sender
{
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    [pasteBoard setString:_messageLabel.text];
}

- (void)deleteObject:(id)sender
{
    _deleteObject(self);
}


@end
