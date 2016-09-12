//
//  ProcessView.m
//  FDHello
//
//  Created by BUPT on 16/8/24.
//  Copyright © 2016年 FireMonkey. All rights reserved.
//

#import "ProcessView.h"

@implementation ProcessView

- (void)drawRect:(CGRect)rect {
    //仪表盘底部
    drawProcessBottom();
    //仪表盘进度
    [self drawProcess];
}
-(void)drawProcess
{
    //1.获取上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    //1.1 设置线条的宽度
    CGContextSetLineWidth(context, 12);
    //1.2 设置线条的起始点样式
    CGContextSetLineCap(context,kCGLineCapButt);
    //1.3  虚实切换 ，实线5虚线5
    CGFloat length[] = {4,0};
    CGContextSetLineDash(context, 0, length, 2);
    //1.4 设置颜色
    [[UIColor greenColor] set];
    
    //2.添加通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(numberChange:) name:@"number" object:nil];
    CGFloat end = -5*M_PI_4+(6*M_PI_4*_num/100);
    
    CGContextAddArc(context, SCREEN_WIDTH/2 , SCREEN_HEIGHT*0.28, SCREEN_HEIGHT*0.12, -5*M_PI_4, end , 0);
    
    //3.绘制
    CGContextStrokePath(context);
    
}

-(void)numberChange:(NSNotification*)text
{
    _num = [text.userInfo[@"num"] intValue];
    dispatch_async(dispatch_get_main_queue(), ^{
         _numLabel.text = [[NSString stringWithFormat:@"%d",_num] stringByAppendingString:@"%"];
        [self setNeedsDisplay];
    });
}

void drawProcessBottom()
{
    //1.获取上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    //1.1 设置线条的宽度
    CGContextSetLineWidth(context, 12);
    //1.2 设置线条的起始点样式
    CGContextSetLineCap(context,kCGLineCapButt);
    //1.3  虚实切换 ，实线5虚线5
    CGFloat length[] = {4,0};
    CGContextSetLineDash(context, 0, length, 2);
    //1.4 设置颜色
    [[UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1] set];
    //2.设置路径
    CGContextAddArc(context, SCREEN_WIDTH/2 , SCREEN_HEIGHT*0.28, SCREEN_HEIGHT*0.12, -5*M_PI_4, M_PI_4, 0);
    //3.绘制
    CGContextStrokePath(context);
    
}

-(void)setNum:(int)num
{
    _num = num;
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _numLabel = [[UILabel alloc]initWithFrame:CGRectMake((SCREEN_WIDTH-120)/2, SCREEN_HEIGHT*0.21, 120, SCREEN_HEIGHT*0.12)];
        _numLabel.textAlignment  = NSTextAlignmentCenter;
        _numLabel.textColor = [UIColor blackColor];
        _numLabel.font = [UIFont systemFontOfSize:45];
        _numLabel.text = @"0%";
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(change) name:@"train" object:nil];
        [self addSubview:_numLabel];
    }
    return self;
}
-(void)change
{
    _num +=2;
    if (_num > 100) {
        _num = 0;
    }
    NSDictionary *dic = [[NSDictionary alloc]initWithObjectsAndKeys:[NSString stringWithFormat:@"%d",_num],@"num", nil];
    //创建通知
    NSNotification *noti = [NSNotification notificationWithName:@"number" object:nil userInfo:dic];
    //发送通知
    [[NSNotificationCenter defaultCenter]postNotification:noti];
    
}


@end
