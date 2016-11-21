//
//  SCNavigationController.m
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-17.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import "SCNavigationController.h"
#import "SCCaptureCameraController.h"

@interface SCNavigationController ()

@property (nonatomic, assign) BOOL isStatusBarHiddenBeforeShowCamera;

@end

@implementation SCNavigationController

+(void)initialize {
    //导航栏颜色
    UINavigationBar *barAppearance = [UINavigationBar appearance];
    barAppearance.barStyle = UIBarStyleBlack;
    UIBarButtonItem *itemAppearance = [UIBarButtonItem appearance];
    //设置普通状态
    NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
    textAttrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
    textAttrs[NSFontAttributeName] = [UIFont systemFontOfSize:15];
    [itemAppearance setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationBarHidden = NO;
    self.hidesBottomBarWhenPushed = NO;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];

//    _isStatusBarHiddenBeforeShowCamera = [UIApplication sharedApplication].statusBarHidden;
//    if ([UIApplication sharedApplication].statusBarHidden == NO) {
//        //iOS7，需要plist里设置 View controller-based status bar appearance 为NO
//        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
//    }
    
}

- (void)dealloc {
    //status bar
//    if ([UIApplication sharedApplication].statusBarHidden != _isStatusBarHiddenBeforeShowCamera) {
//        [[UIApplication sharedApplication] setStatusBarHidden:_isStatusBarHiddenBeforeShowCamera withAnimation:UIStatusBarAnimationFade];
//    }
}

#pragma mark - pop
- (void)dismissModalViewControllerAnimated:(BOOL)animated {
    BOOL shouldToDismiss = YES;
    if ([self.scNaigationDelegate respondsToSelector:@selector(willDismissNavigationController:)]) {
        shouldToDismiss = [self.scNaigationDelegate willDismissNavigationController:self];
    }
    if (shouldToDismiss) {
        [super dismissModalViewControllerAnimated:animated];
    }
}

#pragma mark - action(s)
- (void)showCameraWithParentController:(UIViewController*)parentController {
    SCCaptureCameraController *con = [[SCCaptureCameraController alloc] init];
    [self setViewControllers:[NSArray arrayWithObjects:con, nil]];

    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [parentController presentViewController:self animated:YES completion:nil];
}


#define CAN_ROTATE  0

#pragma mark -------------rotate---------------
// <iOS6
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
#if CAN_ROTATE
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
#else
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
#endif
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0
//iOS6+
- (BOOL)shouldAutorotate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
#if CAN_ROTATE
    return YES;
#else
    return NO;
#endif
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
//    return [UIApplication sharedApplication].statusBarOrientation;
	return UIInterfaceOrientationPortrait;
}
#endif

@end
