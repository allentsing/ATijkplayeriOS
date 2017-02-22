//
//  SWHomeViewController.m
//  PanoramicPlatform
//
//  Created by WhistlingArrow on 24/11/2016.
//  Copyright © 2016 童冀. All rights reserved.
//

#import "SWHomeViewController.h"
#import "ZHCameraPreviewViewController.h"

@interface SWHomeViewController ()

@end

@implementation SWHomeViewController

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

#pragma mark - event response
- (IBAction)cameraButtonClicked:(id)sender {
    //    [[SWAeeCameraManager sharedManager] startSession];
    
    ZHCameraPreviewViewController * xxVC = [[ZHCameraPreviewViewController alloc] init];
    //    ZHTestViewController * xxVC = [[ZHTestViewController alloc] init];
    //    ZHLivingViewController * xxVC = [[ZHLivingViewController alloc] init];
    [self.navigationController pushViewController:xxVC animated:YES];
}

@end
