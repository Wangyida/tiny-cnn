//
//  TrainViewController.m
//  FDHello
//
//  Created by BUPT on 16/8/23.
//  Copyright © 2016年 FireMonkey. All rights reserved.
//

#import "TrainViewController.h"
#import "ProcessView.h"
#import "ResultView.h"

@interface TrainViewController ()<UITableViewDataSource,UITableViewDelegate>

@end

@implementation TrainViewController
ProcessView *processView;
UILabel *noticeText;
UILabel *timeText;
UILabel *accuracyText;
UIButton *startTrainBtn;
int leftTimes;
NSMutableArray *resultDataArray;
UITableView *resultDataTable;

- (void)viewDidLoad {
    [super viewDidLoad];
    processView = [[ProcessView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT*0.4)];
    processView.backgroundColor = [UIColor whiteColor];
    processView.hidden = YES;
    processView.num = 0 ;
    
    noticeText = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH*0.04, SCREEN_HEIGHT*0.44, SCREEN_WIDTH*0.92, SCREEN_HEIGHT*0.06)];
    noticeText.font  = [UIFont systemFontOfSize:18.0f];
    noticeText.textAlignment = NSTextAlignmentCenter;
    noticeText.text = @"训练将持续较长时间，请谨慎操作！";
    
    timeText = [[UILabel alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT*0.53, SCREEN_WIDTH*0.5, SCREEN_HEIGHT*0.06)];
    timeText.hidden = YES;
    timeText.font  = [UIFont systemFontOfSize:16.0f];
    timeText.textAlignment = NSTextAlignmentCenter;
    timeText.backgroundColor = [UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1];
    timeText.text =  @"训练用时";
    
    accuracyText = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH*0.5, SCREEN_HEIGHT*0.53, SCREEN_WIDTH*0.5, SCREEN_HEIGHT*0.06)];
    accuracyText.hidden = YES;
    accuracyText.font  = [UIFont systemFontOfSize:16.0f];
    accuracyText.textAlignment = NSTextAlignmentCenter;
    accuracyText.backgroundColor = [UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1];
    accuracyText.text = @"正确率";
    
    startTrainBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    startTrainBtn.frame = CGRectMake(SCREEN_WIDTH*0.1, SCREEN_HEIGHT*0.58, SCREEN_WIDTH*0.8, SCREEN_HEIGHT*0.06);
    startTrainBtn.layer.cornerRadius = 4;
    [startTrainBtn setTitle:@"开始训练" forState:UIControlStateNormal] ;
    startTrainBtn.titleLabel.font = [UIFont systemFontOfSize:20.0f];
    [startTrainBtn addTarget:self action:@selector(startTrain) forControlEvents:UIControlEventTouchUpInside];
    startTrainBtn.backgroundColor = [UIColor colorWithRed:51.0/255.0 green:204.0/255.0 blue:255.0/255.0 alpha:1];
    
    resultDataTable = [[UITableView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT*0.59, SCREEN_WIDTH, SCREEN_HEIGHT*0.4)];
    [resultDataTable setDelegate:self];
    [resultDataTable setDataSource:self];
    resultDataTable.hidden = YES ;
    [resultDataTable setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [resultDataTable setTableHeaderView:[[UIView alloc] initWithFrame:CGRectZero]];
    //解决tableView分割线左边不到边的情况
    if ([resultDataTable respondsToSelector:@selector(setSeparatorInset:)]) {
        [resultDataTable setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([resultDataTable respondsToSelector:@selector(setLayoutMargins:)]) {
        [resultDataTable setLayoutMargins:UIEdgeInsetsZero];
    }
    resultDataTable.rowHeight = SCREEN_HEIGHT*0.1;
    
    [self.view addSubview:processView];
    [self.view addSubview:noticeText];
    [self.view addSubview:timeText];
    [self.view addSubview:accuracyText];
    [self.view addSubview:startTrainBtn];
    [self.view addSubview:resultDataTable];
    
    resultDataArray = [[NSMutableArray alloc] init];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startTrain{
    [self.navigationItem setHidesBackButton:YES];
    const char* queueName = [[[NSDate date] description] UTF8String];
    dispatch_queue_t myQueue = dispatch_queue_create(queueName, NULL);
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
        noticeText.text = @"数据加载中，请稍候!";
        startTrainBtn.hidden = YES;
        dispatch_async(myQueue, ^{
            const char *startTrainPath = [[[NSBundle mainBundle] resourcePath] UTF8String];
            train_lenet(startTrainPath);
            [self.navigationItem setHidesBackButton:NO];
            noticeText.text = @"保存完毕，开始识别数字吧！";
        });
    });
}

//训练函数
void train_lenet(std::string data_dir_path) {
    // specify loss-function and learning strategy
    network<sequential> nn;
    adagrad optimizer;
    construct_net(nn);
    std::cout << "load models..." << std::endl;
    // load MNIST dataset
    std::vector<label_t> train_labels, test_labels;
    std::vector<vec_t> train_images, test_images;
    
    parse_mnist_labels(data_dir_path+"/t10k-labels.idx1-ubyte",
                       &train_labels);
    parse_mnist_images(data_dir_path+"/t10k-images.idx3-ubyte",
                       &train_images, -1.0, 1.0, 2, 2);
    parse_mnist_labels(data_dir_path+"/t10k-labels.idx1-ubyte",
                       &test_labels);
    parse_mnist_images(data_dir_path+"/t10k-images.idx3-ubyte",
                       &test_images, -1.0, 1.0, 2, 2);
    std::cout << "start training" << std::endl;
    dispatch_async(dispatch_get_main_queue(), ^{
        noticeText.text = @"训练开始，请耐心等待!";
        processView.hidden = NO ;
    });
    progress_display disp(train_images.size());
    timer t;
    int minibatch_size = 10;
    int num_epochs = 30;
    leftTimes = num_epochs ;
    
    optimizer.alpha *= static_cast<tiny_cnn::float_t>(std::sqrt(minibatch_size));
    
    // create callback
    auto on_enumerate_epoch = [&](){
        std::cout << t.elapsed() << "s elapsed." << std::endl;
        dispatch_async(dispatch_get_main_queue(), ^{
            noticeText.text = @"火猴正在计算训练用时和正确率，请稍候!";
        });
        tiny_cnn::result res = nn.test(test_images, test_labels);
        std::cout << res.num_success << "/" << res.num_total << std::endl;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *resultArr = [[NSArray alloc] initWithObjects:[[NSString stringWithFormat:@"%.3f",t.elapsed()] stringByAppendingString:@"s"], [NSString stringWithFormat:@"%d",res.num_success] ,[NSString stringWithFormat:@"%d",res.num_total], nil];
            [resultDataArray addObject:resultArr];
            [resultDataTable reloadData];
            resultDataTable.hidden = NO ;
            timeText.hidden = NO;
            accuracyText.hidden = NO;
            leftTimes --;
            if(leftTimes > 0 ){
                noticeText.text = [NSString stringWithFormat:@"训练还未结束，第%d轮开始，共%d轮!",num_epochs-leftTimes+1,num_epochs];
            }else{
                noticeText.text = @"训练结束!正在保存训练结果！";
            }
        });
        disp.restart(train_images.size());
        t.restart();
    };
    
    auto on_enumerate_minibatch = [&](){
        disp += minibatch_size;
    };
    
    // training
    nn.train<mse>(optimizer, train_images, train_labels, minibatch_size, num_epochs,
                  on_enumerate_minibatch, on_enumerate_epoch);
    
    std::cout << "end training." << std::endl;
    // test and show results
    nn.test(test_images, test_labels).print_detail(std::cout);
    
    // save networks
    std::ofstream ofs([[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES)[0] stringByAppendingPathComponent:@"LeNet-weightsNew.txt"] UTF8String]);
    ofs << nn;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  ([resultDataArray count]);
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%ld",(long)indexPath.row];
    UITableViewCell *cell = (UITableViewCell*)[tableView  dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    UILabel *left  = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH*0.5, SCREEN_HEIGHT*0.1)];
    left.textAlignment  = NSTextAlignmentCenter;
    ResultView *VW = [[ResultView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT*0.1)];
    if(resultDataArray.count != 0){
        NSArray *recordDic = [resultDataArray objectAtIndex:indexPath.row];
        left.text  = [NSString stringWithFormat:@"%@",recordDic[0]];
        VW.numResult = [recordDic[1] doubleValue]/[recordDic[2] doubleValue]*100;
        [cell.contentView addSubview:VW];
        [cell.contentView addSubview:left];
    }
    return cell;
}

@end
