//
//  FDUtils.m
//  ShenFenTong3
//
//  Created by mac on 16/8/5.
//  Copyright © 2016年 BUPT. All rights reserved.
//

#import "FDUtil.h"

@implementation FDUtil

// MARK: functions

UIColor * FDColorWithHex(long hex) {
    float red = ((float)((hex & 0xFF0000) >> 16)) / 255.0;
    float green = ((float)((hex & 0xFF00) >> 8)) / 255.0;
    float blue = ((float)(hex & 0xFF)) / 255.0;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
}


UIStoryboard * FDStoryBoard(NSString *name) {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:name bundle:nil];
    return storyboard;
    
}

void construct_net(network<sequential>& nn) {
    // connection table [Y.Lecun, 1998 Table.1]
#define O true
#define X false
    static const bool tbl[] = {
        O, X, X, X, O, O, O, X, X, O, O, O, O, X, O, O,
        O, O, X, X, X, O, O, O, X, X, O, O, O, O, X, O,
        O, O, O, X, X, X, O, O, O, X, X, O, X, O, O, O,
        X, O, O, O, X, X, O, O, O, O, X, X, O, X, O, O,
        X, X, O, O, O, X, X, O, O, O, O, X, O, O, X, O,
        X, X, X, O, O, O, X, X, O, O, O, O, X, O, O, O
    };
#undef O
#undef X
    
    // construct nets
    nn << convolutional_layer<tan_h>(32, 32, 5, 1, 6)  // C1, 1@32x32-in, 6@28x28-out
    << average_pooling_layer<tan_h>(28, 28, 6, 2)   // S2, 6@28x28-in, 6@14x14-out
    << convolutional_layer<tan_h>(14, 14, 5, 6, 16,
                                  connection_table(tbl, 6, 16))              // C3, 6@14x14-in, 16@10x10-in
    << average_pooling_layer<tan_h>(10, 10, 16, 2)  // S4, 16@10x10-in, 16@5x5-out
    << convolutional_layer<tan_h>(5, 5, 5, 16, 120) // C5, 16@5x5-in, 120@1x1-out
    << fully_connected_layer<tan_h>(120, 10);       // F6, 120-in, 10-out
}

@end


// MARK: UIView Category

@implementation UIView (CornerRadius)

#pragma mark - setter & getter

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
    self.layer.masksToBounds = YES;
    [self setNeedsDisplay];
}

- (CGFloat)cornerRadius {
    return self.layer.cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
    self.layer.masksToBounds = YES;
    [self setNeedsDisplay];
}

- (CGFloat)borderWidth {
    return self.layer.borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor {
    if (borderColor) {
        self.layer.borderColor = borderColor.CGColor;
    }
    [self setNeedsDisplay];
}

- (UIColor *)borderColor {
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

@end

