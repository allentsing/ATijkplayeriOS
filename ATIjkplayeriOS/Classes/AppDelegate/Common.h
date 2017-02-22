//
//  Common.h
//  AVVideo_Record_Prj
//
//  Created by 魏靖南 on 11/5/15.
//  Copyright © 2015 魏靖南. All rights reserved.
//

#ifndef Common_h
#define Common_h

//登陆的一些验证信息
#define UID_INFO [[NSUserDefaults standardUserDefaults] objectForKey:@"uid"]
#define TOKEN_INFO [[NSUserDefaults standardUserDefaults] objectForKey:@"token"]
#define ID_7D_INFO [[NSUserDefaults standardUserDefaults] objectForKey:@"UserId"]
#define UserName_INFO [[NSUserDefaults standardUserDefaults] objectForKey:@"username"]

//判断版本号
#define CUR_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
#define CLEAN_FLAG [[NSUserDefaults standardUserDefaults] objectForKey:@"clean_flag"]
#define ISHOW_INSTALLED [[NSUserDefaults standardUserDefaults] boolForKey:@"is_installed"]

//Push info
#define NSUserDefaults_Key_DeviceToken @"DeviceToken"
#define NSUserDefaults_Key_PostDeviceIDAndToken @"PostDeviceIDAndToken"

//Userful Macro
#define WS(weakSelf) __weak __typeof(&*self) weakSelf = self
#define STS(strongSefl) __strong __typeof(&*self) strongSelf = self

//屏幕尺寸
#define SCREEN_WIDTH    ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT   ([[UIScreen mainScreen] bounds].size.height)

//亮色
#define LIGHT_COLOR [UIColor colorWithRed:157/255.0 green:210/255.0 blue:237/255.0 alpha:1.0]
#define LIGHT_BACKGROUND_COLOR [UIColor colorWithRed:242/255.0 green:233/255.0 blue:219/255.0 alpha:1.0]
#define LIGHT_TEXT_COLOR [UIColor colorWithRed:157/255.0 green:210/255.0 blue:237/255.0 alpha:1.0]
//固件版本
#define iOSVersion [[[UIDevice currentDevice] systemVersion] floatValue]

//判断软件版本
#define SoftwareVersion [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]

//判断的机器型号
#define IS_IPHONE4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)

#define IS_IPHONE5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

#define IS_IPHONE6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? (CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size)) : NO)

#define IS_IPHONE6PLUS ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? (CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size)) : NO)

#define IS_IPHONE6PLUS_BIGGER ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? (CGSizeEqualToSize(CGSizeMake(1125, 2001), [[UIScreen mainScreen] currentMode].size)) : NO)

//Color RGB Method
#define UIColorFromRGB_dec(r,g,b) [UIColor colorWithRed:r/256.f green:g/256.f blue:b/256.f alpha:1.f]
#define UIColorFromRGBA_dec(r,g,b,a) [UIColor colorWithRed:r/256.f green:g/256.f blue:b/256.f alpha:a]
#define UIColorFromRGB_hex(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0x0000FF))/255.0 \
alpha:1.0]

#define UIColorFromRGBA_hex(rgbValue, alphaValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0x0000FF))/255.0 \
alpha:alphaValue]

#endif /* Common_h */
