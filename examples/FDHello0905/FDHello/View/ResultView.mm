//
//  ProcessView.m
//  FDHello
//
//  Created by BUPT on 16/8/24.
//  Copyright © 2016年 FireMonkey. All rights reserved.
//

#import "ResultView.h"

@implementation ResultView

- (void)drawRect:(CGRect)rect {
    //仪表盘底部
    drawBottom();
    //仪表盘进度
    [self drawTop];
    //显示中间数字
    _numResultLabel.text = [[NSString stringWithFormat:@"%.2f",_numResult] stringByAppendingString:@"%"];
}
-(void)drawTop
{
    //1.获取上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    //1.1 设置线条的宽度
    CGContextSetLineWidth(context, 6);
    //1.2 设置线条的起始点样式
    CGContextSetLineCap(context,kCGLineCapButt);
    //1.3  虚实切换 ，实线4虚线0
    CGFloat length[] = {4,0};
    CGContextSetLineDash(context, 0, length, 2);
    //1.4 设置颜色
    [[UIColor colorWithRed:51.0/255.0 green:204.0/255.0 blue:255.0/255.0 alpha:1] set];
    
    CGFloat end = -5*M_PI_4+(6*M_PI_4*_numResult/100);
    
    CGContextAddArc(context, 3*SCREEN_WIDTH/4 ,40, 30, -5*M_PI_4, end , 0);
    
    //3.绘制
    CGContextStrokePath(context);
    
}

void drawBottom()
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 6);
    CGContextSetLineCap(context,kCGLineCapButt);
    CGFloat length[] = {4,0};
    CGContextSetLineDash(context, 0, length, 2);
    [[UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1] set];
    CGContextAddArc(context, 3*SCREEN_WIDTH/4 ,40 , 30, -5*M_PI_4, M_PI_4, 0);
    CGContextStrokePath(context);
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    self.backgroundColor = [UIColor whiteColor];
    if (self) {
        _numResultLabel = [[UILabel alloc]initWithFrame:CGRectMake((3*SCREEN_WIDTH/2-50)/2 ,30 ,50, 15)];
        _numResultLabel.textAlignment  = NSTextAlignmentCenter;
        _numResultLabel.textColor = [UIColor blackColor];
        _numResultLabel.font = [UIFont systemFontOfSize:10.0f];
        [self addSubview:_numResultLabel];
    }
    return self;
}

@end
