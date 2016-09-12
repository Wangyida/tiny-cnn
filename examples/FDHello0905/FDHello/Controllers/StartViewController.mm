//
//  startViewController.m
//  FDHello
//
//  Created by BUPT on 16/8/21.
//  Copyright © 2016年 FireMonkey. All rights reserved.
//

#import "StartViewController.h"

@interface StartViewController ()
//- (IBAction)classifyBtn:(id)sender;

@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
