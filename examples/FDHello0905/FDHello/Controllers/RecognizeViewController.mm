//
//  TestViewController.m
//  FDHello
//
//  Created by BUPT on 16/8/13.
//  Copyright © 2016年 FireMonkey. All rights reserved.
//

#import "RecognizeViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import <CoreImage/CoreImage.h>
#import "FDUtil.h"

@interface RecognizeViewController ()<UIImagePickerControllerDelegate ,UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *Score1;
@property (weak, nonatomic) IBOutlet UILabel *Score2;
@property (weak, nonatomic) IBOutlet UILabel *Score3;
@property (weak, nonatomic) IBOutlet UIImageView *backImg1;
@property (weak, nonatomic) IBOutlet UIImageView *backImg2;
@property (weak, nonatomic) IBOutlet UIImageView *backImg3;
@property (weak, nonatomic) IBOutlet UILabel *first;
@property (weak, nonatomic) IBOutlet UILabel *second;
@property (weak, nonatomic) IBOutlet UILabel *third;
- (IBAction)startRecognize:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *startRecognize;

@end

@implementation RecognizeViewController
NSMutableArray * resultArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    _Score1.text = @"请点击按钮，开始火猴识数吧！";
    _Score1.textAlignment = NSTextAlignmentCenter;
    _Score2.hidden = YES;
    _Score3.hidden = YES;
    _first.hidden = YES;
    _second.hidden = YES;
    _third.hidden = YES;
    _backImg2.hidden = YES;
    _backImg3.hidden = YES;
    _startRecognize.cornerRadius = 4;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// rescale output to 0-100
template <typename Activation>
double rescale(double x) {
    Activation a;
    return 100.0 * (x - a.scale().first) / (a.scale().second - a.scale().first);
}

// convert tiny_cnn::image to cv::Mat and resize
cv::Mat image2mat(image<>& img) {
    cv::Mat ori(img.height(), img.width(), CV_8U, &img.at(0, 0));
    cv::Mat resized;
    cv::resize(ori, resized, cv::Size(), 3, 3, cv::INTER_AREA);
    return resized;
}

void convert_image(const cv::Mat& imagefilename,
                   double minv,
                   double maxv,
                   int w,
                   int h,
                   vec_t& data) {
    cv::Mat img;
    cv::cvtColor(imagefilename, img, CV_RGB2GRAY);
    if (img.data == nullptr) return; // cannot open, or it's not an image
    
    cv::Mat_<uint8_t> resized;
    cv::resize(img, resized, cv::Size(w, h));
    
    // mnist dataset is "white on black", so negate required
    std::transform(resized.begin(), resized.end(), std::back_inserter(data),
                   [=](uint8_t c) { return (255 - c) * (maxv - minv) / 255.0 + minv; });
}

void recognize(const std::string& dictionary, const cv::Mat& filename) {
    network<sequential> nn;
    
    construct_net(nn);
    
    // load nets
    ifstream ifs(dictionary.c_str());
    ifs >> nn;
    
    // convert imagefile to vec_t
    vec_t data;
    convert_image(filename, -1.0, 1.0, 32, 32, data);
    
    // recognize
    auto res = nn.predict(data);
    vector<pair<double, int> > scores;
    
    // sort & print top-3
    for (int i = 0; i < 10; i++)
        scores.emplace_back(rescale<tan_h>(res[i]), i);
    
    sort(scores.begin(), scores.end(), greater<pair<double, int>>());
    
    resultArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < 3; i++){
        cout << scores[i].second << "," << scores[i].first << endl;
        [resultArray addObject:[NSString stringWithFormat:@"%d",scores[i].second ] ];
        [resultArray addObject:[NSString stringWithFormat:@"%f",scores[i].first]];
    }
    
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

//取消的情况下
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
//使用照片的后续处理
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [picker dismissViewControllerAnimated:YES completion:^() {
        NSString *trainTxtInDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES)[0] stringByAppendingPathComponent:@"LeNet-weightsNew.txt"];
        
        //若用户未进行训练，则加载原始训练后的文件
        if (![[NSFileManager defaultManager] fileExistsAtPath:trainTxtInDocPath]) {
            trainTxtInDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES)[0] stringByAppendingPathComponent:@"LeNet-weights.txt"];
        }
        NSLog(@"%@",trainTxtInDocPath);
        const char *trainPath = [trainTxtInDocPath UTF8String];
        UIImage * testImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        recognize(trainPath , [self cvMatFromUIImage:testImg]);
        _backImg1.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.png",[[resultArray objectAtIndex:0] intValue]]];
        self.Score1.text = [NSString stringWithFormat:@"相似度：%.3f", [[resultArray objectAtIndex:1] doubleValue]];
        self.Score1.textAlignment = NSTextAlignmentLeft ;
        _backImg2.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.png",[[resultArray objectAtIndex:2] intValue]]];
        self.Score2.text = [NSString stringWithFormat:@"相似度：%.3f", [[resultArray objectAtIndex:3] doubleValue]];
        _backImg3.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.png",[[resultArray objectAtIndex:4] intValue]]];
        self.Score3.text = [NSString stringWithFormat:@"相似度：%.3f", [[resultArray objectAtIndex:5] doubleValue]];
        _startRecognize.titleLabel.text = @"重新识别";
        _Score1.hidden = NO;
        _Score2.hidden = NO;
        _Score3.hidden = NO;
        _first.hidden = NO;
        _second.hidden = NO;
        _third.hidden = NO;
        _backImg2.hidden = NO;
        _backImg3.hidden = NO;
        
    }];
}

#pragma mark camera utility
//- (BOOL) isCameraAvailable{
//    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
//}
//
//- (BOOL) isRearCameraAvailable{
//    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
//}
//
//- (BOOL) isFrontCameraAvailable {
//    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
//}
//
//- (BOOL) doesCameraSupportTakingPhotos {
//    return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
//}
//
//- (BOOL) isPhotoLibraryAvailable{
//    return [UIImagePickerController isSourceTypeAvailable:
//            UIImagePickerControllerSourceTypePhotoLibrary];
//}
//- (BOOL) canUserPickVideosFromPhotoLibrary{
//    return [self
//            cameraSupportsMedia:(__bridge NSString *)kUTTypeMovie sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
//}
//- (BOOL) canUserPickPhotosFromPhotoLibrary{
//    return [self
//            cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
//}
//
//- (BOOL) cameraSupportsMedia:(NSString *)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType{
//    __block BOOL result = NO;
//    if ([paramMediaType length] == 0) {
//        return NO;
//    }
//    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
//    [availableMediaTypes enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
//        NSString *mediaType = (NSString *)obj;
//        if ([mediaType isEqualToString:paramMediaType]){
//            result = YES;
//            *stop= YES;
//        }
//    }];
//    return result;
//}

- (IBAction)startRecognize:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    //按钮：从相册选择，类型：UIAlertActionStyleDefault
    [alert addAction:[UIAlertAction actionWithTitle:@"从相册中选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UIImagePickerController *PickerImage = [[UIImagePickerController alloc]init];
        
        PickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
        [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
        PickerImage.mediaTypes = mediaTypes;
        
        PickerImage.delegate = self;
        
        [self presentViewController:PickerImage animated:YES completion:nil];
    }]];
    //按钮：拍照，类型：UIAlertActionStyleDefault
    [alert addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        
        UIImagePickerController *PickerImage = [[UIImagePickerController alloc]init];
        
        PickerImage.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        PickerImage.delegate = self;
        
        [self presentViewController:PickerImage animated:YES completion:nil];
    }]];
    //按钮：取消，类型：UIAlertActionStyleCancel
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
