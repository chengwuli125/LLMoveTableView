//
//  ViewController.m
//  LLMoveTableView
//
//  Created by cwli on 16/3/5.
//  Copyright © 2016年 lichengwu. All rights reserved.
//

#import "ViewController.h"
#import "LLTestMoveTableViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(100, 150, 100, 100);
    button.layer.cornerRadius = 3.f;
    button.backgroundColor = [UIColor redColor];
    [button addTarget:self action:@selector(buttonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)buttonClicked {
    LLTestMoveTableViewController *controller = [[LLTestMoveTableViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
