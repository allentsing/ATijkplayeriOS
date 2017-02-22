//
//  ZHCameraPreviewViewController.h
//  PanoramicPlatform
//
//  Created by 朱航杰 on 2016/11/24.
//  Copyright © 2016年 童冀. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IJKMediaFramework/IJKMediaFramework.h>
@class IJKMediaControl;

typedef enum {
    SwipeGestureTypeLeft = 0,
    SwipeGestureTypeMiddle,
    SwipeGestureTypeRight
}SwipeGestureType;

@interface ZHCameraPreviewViewController : UIViewController

@property (nonatomic, assign) SwipeGestureType swipeGestureType;
@property(atomic,strong) NSURL *url;
@property(atomic, retain) id<IJKMediaPlayback> player;

@end
