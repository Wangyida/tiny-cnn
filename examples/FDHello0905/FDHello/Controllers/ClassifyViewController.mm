//
//  ClassifyViewController.m
//  FDHello
//
//  Created by iMac-8201 on 16/8/29.
//  Copyright © 2016年 FireMonkey. All rights reserved.
//

#import "ClassifyViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import <CoreImage/CoreImage.h>
#import "FDUtil.h"

@interface ClassifyViewController ()<UIImagePickerControllerDelegate ,UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *classifyBackImg;

@end

@implementation ClassifyViewController
UIButton *startClassifyBtn;
- (void)viewDidLoad {
    [super viewDidLoad];
    startClassifyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    startClassifyBtn.frame = CGRectMake(SCREEN_WIDTH*0.1, SCREEN_HEIGHT*0.75, SCREEN_WIDTH*0.8, SCREEN_HEIGHT*0.06);
    startClassifyBtn.layer.cornerRadius = 4;
    [startClassifyBtn setTitle:@"开始分类" forState:UIControlStateNormal] ;
    startClassifyBtn.titleLabel.font = [UIFont systemFontOfSize:20.0f];
    [startClassifyBtn addTarget:self action:@selector(startClassify) forControlEvents:UIControlEventTouchUpInside];
    startClassifyBtn.backgroundColor = [UIColor colorWithRed:51.0/255.0 green:204.0/255.0 blue:255.0/255.0 alpha:1];
    [self.view addSubview:startClassifyBtn];
}

cv::Mat compute_mean(const string& mean_file, int width, int height)
{
    caffe::BlobProto blob;
    detail::read_proto_from_binary(mean_file, &blob);

    vector<cv::Mat> channels;
    auto data = blob.mutable_data()->mutable_data();

    for (int i = 0; i < blob.channels(); i++, data += blob.height() * blob.width())
        channels.emplace_back(blob.height(), blob.width(), CV_32FC1, data);

    cv::Mat mean;
    cv::merge(channels, mean);

    return cv::Mat(cv::Size(width, height), mean.type(), cv::mean(mean));
}

cv::ColorConversionCodes get_cvt_codes(int src_channels, int dst_channels)
{
    assert(src_channels != dst_channels);

    if (dst_channels == 3)
        return src_channels == 1 ? cv::COLOR_GRAY2BGR : cv::COLOR_BGRA2BGR;
    else if (dst_channels == 1)
        return src_channels == 3 ? cv::COLOR_BGR2GRAY : cv::COLOR_BGRA2GRAY;
    else
        throw runtime_error("unsupported color code");
}

void preprocess(const cv::Mat& img,
                const cv::Mat& mean,
                int num_channels,
                cv::Size geometry,
                vector<cv::Mat>* input_channels)
{
    cv::Mat sample;

    // convert color
    if (img.channels() != num_channels)
        cv::cvtColor(img, sample, get_cvt_codes(img.channels(), num_channels));
    else
        sample = img;

    // resize
    cv::Mat sample_resized;
    cv::resize(sample, sample_resized, geometry);

    cv::Mat sample_float;
    sample_resized.convertTo(sample_float, num_channels == 3 ? CV_32FC3 : CV_32FC1);

    // subtract mean
    if (mean.size().width > 0) {
        cv::Mat sample_normalized;
        cv::subtract(sample_float, mean, sample_normalized);
        cv::split(sample_normalized, *input_channels);
    }
    else {
        cv::split(sample_float, *input_channels);
    }
}

vector<string> get_label_list(const string& label_file)
{
    string line;
    ifstream ifs(label_file.c_str());

    if (ifs.fail() || ifs.bad())
        throw runtime_error("failed to open:" + label_file);

    vector<string> lines;
    while (getline(ifs, line))
        lines.push_back(line);

    return lines;
}

void load_validation_data(const std::string& validation_file,
                          std::vector<std::pair<std::string, int>>* validation) {
    string line;
    ifstream ifs(validation_file.c_str());

    if (ifs.fail() || ifs.bad()) {
        throw runtime_error("failed to open:" + validation_file);
    }

    vector<string> lines;
    while (getline(ifs, line)) {
        lines.push_back(line);
    }
}

void test(const string& model_file,
          const string& trained_file,
          const string& mean_file,
          const string& label_file,
          const string& img_file)
{
    auto labels = get_label_list(label_file);
    auto net = create_net_from_caffe_prototxt(model_file);
    reload_weight_from_caffe_protobinary(trained_file, net.get());

    int channels = (*net)[0]->in_data_shape()[0].depth_;
    int width = (*net)[0]->in_data_shape()[0].width_;
    int height = (*net)[0]->in_data_shape()[0].height_;

    std::vector<std::pair<std::string, int>> validation(1);
    load_validation_data(img_file, &validation);

    auto mean = compute_mean(mean_file, width, height);

    for (size_t i = 0; i < validation.size(); ++i) {

        cv::Mat img = cv::imread(img_file, -1);
        //cv::Mat img = cv::imread(validation[i].first, -1);

        vector<float> inputvec(width*height*channels);
        vector<cv::Mat> input_channels;

        for (int i = 0; i < channels; i++)
            input_channels.emplace_back(height, width, CV_32FC1, &inputvec[width*height*i]);

        preprocess(img, mean, 3, cv::Size(width, height), &input_channels);

        vector<tiny_cnn::float_t> vec(inputvec.begin(), inputvec.end());

        clock_t begin = clock();

        auto result = net->predict(vec);

        clock_t end = clock();
        double elapsed_secs = double(end - begin) / CLOCKS_PER_SEC;
        cout <<"Elapsed time(s): " << elapsed_secs << endl;

        vector<tiny_cnn::float_t> sorted(result.begin(), result.end());

        int top_n = 5;
        partial_sort(sorted.begin(), sorted.begin()+top_n, sorted.end(), greater<tiny_cnn::float_t>());

        for (int i = 0; i < top_n; i++) {
            size_t idx = distance(result.begin(), find(result.begin(), result.end(), sorted[i]));
            cout << labels[idx] << "," << sorted[i] << endl;
        }
    }
}

-(void) startClassify {
    
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

//取消的情况下
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
//使用照片的后续处理
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [picker dismissViewControllerAnimated:YES completion:^() {
        
        const char *model_file = [[[NSBundle mainBundle] pathForResource:@"deploy" ofType:@"prototxt"] UTF8String];
        const char *trained_file = [[[NSBundle mainBundle] pathForResource:@"bvlc_reference_caffenet" ofType:@"caffemodel"] UTF8String];
        const char *mean_file = [[[NSBundle mainBundle] pathForResource:@"imagenet_mean" ofType:@"binaryproto"] UTF8String];
        const char *label_file = [[[NSBundle mainBundle] pathForResource:@"synset_words" ofType:@"txt"] UTF8String];
        const char *img_file = [[[NSBundle mainBundle] pathForResource:@"FireMonkey" ofType:@"jpg"] UTF8String];
        try {
            test(model_file,trained_file,mean_file,label_file,img_file);
        } catch (const nn_error& e) {
            cout << e.what() << endl;
        }
        
//        // 改成cvmat格式的图片
//        UIImage * testImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
//        _classifyBackImg.image = testImg;

        startClassifyBtn.titleLabel.text = @"重新分类";
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
