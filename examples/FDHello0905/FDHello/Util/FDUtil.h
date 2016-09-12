//
//  FDUtils.h
//  ShenFenTong3
//
//  Created by mac on 16/8/5.
//  Copyright © 2016年 BUPT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <iostream>
#include <memory>
#include <ctime>
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include "tiny_cnn.h"
#include "caffe.pb.h"
#include "layer_factory.h"
#include "layer_factory_impl.h"

#define CNN_USE_CAFFE_CONVERTER
using namespace tiny_cnn;
using namespace tiny_cnn::activation;
using namespace std;
using namespace caffe;

NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG
#define FDLog(s, ... ) NSLog( @"[%@ in line %d] -> : %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define FDLog(s, ... )
#endif

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

@interface FDUtil : NSObject


// MARK: 函数
/*!
 *  @brief 根据hex值转换成UIColor。
 *
 */
FOUNDATION_EXPORT UIColor * FDColorWithHex(long hex);

/*!
 *  @brief 获取storyboard，bundle 默认为nil。
 *
 *  @param name storyboard名字。
 *
 */
FOUNDATION_EXPORT UIStoryboard * FDStoryBoard(NSString *name);

void construct_net(network<sequential>& nn);


@end

// MARK: UIView Category
@interface UIView (CornerRadius)

@property (assign, nonatomic) IBInspectable CGFloat  cornerRadius;
@property (assign, nonatomic) IBInspectable CGFloat  borderWidth;
@property (strong, nonatomic) IBInspectable UIColor *borderColor;

@end


NS_ASSUME_NONNULL_END
