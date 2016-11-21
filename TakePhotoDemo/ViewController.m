//
//  ViewController.m
//  TakePhotoDemo
//
//  Created by RRTY on 16/11/7.
//  Copyright © 2016年 deepAI. All rights reserved.
//

#import "ViewController.h"
#import "SCCaptureCameraController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *photoBtn;
@property (weak, nonatomic) IBOutlet UIButton *videoBtn;
@property (weak, nonatomic) IBOutlet UIButton *albumBtn;

@property (weak, nonatomic) IBOutlet UIView *vorViewLeft;
@property (nonatomic,weak) IBOutlet UIView* vorViewRight;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"图像采集";

    [self loadUI];
}

- (void)loadUI {
    
    self.vorViewLeft.layer.borderWidth = 4;
    self.vorViewLeft.layer.borderColor = [UIColor whiteColor].CGColor;
    self.vorViewLeft.backgroundColor = [UIColor orangeColor];
    
    self.vorViewRight.layer.borderWidth = 4;
    self.vorViewRight.layer.borderColor = [UIColor whiteColor].CGColor;
    self.vorViewRight.backgroundColor = [UIColor cyanColor];
    
    self.photoBtn.layer.cornerRadius = 10;
    self.photoBtn.layer.borderWidth = 4;
    self.photoBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    self.photoBtn.clipsToBounds = YES;
    [self.photoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.photoBtn.backgroundColor = [UIColor redColor];
    
    self.videoBtn.layer.cornerRadius = 10;
    self.videoBtn.layer.borderWidth = 4;
    self.videoBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    self.videoBtn.clipsToBounds = YES;
    [self.videoBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.videoBtn.backgroundColor = [UIColor yellowColor];
    
    self.albumBtn.layer.cornerRadius = 10;
    self.albumBtn.layer.borderWidth = 4;
    self.albumBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    self.albumBtn.clipsToBounds = YES;
    [self.albumBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.albumBtn.backgroundColor = [UIColor blueColor];
    
    [self.photoBtn addTarget:self action:@selector(photoBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoBtn addTarget:self action:@selector(videoBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.albumBtn addTarget:self action:@selector(albumBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - clickEvent
- (void)photoBtnClicked:(UIButton *)btn {
    SCCaptureCameraController *cameraVC = [[SCCaptureCameraController alloc] init];
    [self.navigationController pushViewController:cameraVC animated:YES];
}

- (void)videoBtnClicked:(UIButton *)btn {
    
}

- (void)albumBtnClicked:(UIButton *)btn {
    
}
@end
