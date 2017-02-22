//
//  ZHCameraPreviewViewController.m
//  PanoramicPlatform
//
//  Created by 朱航杰 on 2016/11/24.
//  Copyright © 2016年 童冀. All rights reserved.
//

#import "ZHCameraPreviewViewController.h"
#import <LFLiveKit/LFLiveKit.h>
#import "MDVRLibrary.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MovieRecorder.h"

@interface ZHCameraPreviewViewController () <MDVideoFrameAdapterDelegate, LFLiveSessionDelegate, MovieRecorderDelegate>
{
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_videoDevice;
    AVCaptureConnection *_audioConnection;
    AVCaptureConnection *_videoConnection;
    NSDictionary *_videoCompressionSettings;
    NSDictionary *_audioCompressionSettings;
    dispatch_queue_t _sessionQueue;
    dispatch_queue_t _videoDataOutputQueue;
    NSURL *_recordingURL;
    
    NSInteger mvSTATE;
    
}

@property (weak, nonatomic) UIView *PlayerView;
@property (nonatomic,strong) MDVRLibrary* vrLibrary;
@property (nonatomic, strong) LFLiveSession *session;

@property (nonatomic, retain) NSTimer *nextFrameTimer;
@property (nonatomic, strong) NSTimer * progressTimer;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, assign) BOOL isLiving;
@property (nonatomic, assign) NSInteger msSeconds;
@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *photoStatusBtn;
@property (weak, nonatomic) IBOutlet UIButton *videoStatusBtn;
@property (weak, nonatomic) IBOutlet UIButton *livingStatusBtn;
@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UIView *navigationView;

@property (nonatomic, strong) UIProgressView * progress;

@property(nonatomic, retain) __attribute__((NSObject)) CVPixelBufferRef currentPreviewPixelBuffer;
//@property(nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property(nonatomic, retain) __attribute__((NSObject)) CMVideoFormatDescriptionRef outputVideoFormatDescription;
@property(nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;
@property(nonatomic, retain) MovieRecorder *recorder;
@property(nonatomic, readwrite) AVCaptureVideoOrientation videoOrientation;
@property(nonatomic, assign) BOOL recordMark;
@property (nonatomic, strong) UIButton * starButton;
@property (nonatomic, strong) UIButton * stopButton;
@property (nonatomic, strong) UIButton * photoButton;
@property (nonatomic, assign) NSInteger m_frameCount;
@property (nonatomic, assign) BOOL photoMark;
@property (nonatomic, assign) BOOL starLiveMark;

@end

@implementation ZHCameraPreviewViewController

#define LERP(A,B,C) ((A)*(1.0-C)+(B)*C)

- (void)dealloc
{
    [_nextFrameTimer invalidate];
    _nextFrameTimer = nil;
    [_progressTimer invalidate];
    _progressTimer = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)addNavigationButton
{
    UIButton * backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[UIImage imageNamed:@"paishe_icon_back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.backView addSubview:backButton];
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.backView.mas_left).offset(15);
        make.top.equalTo(self.backView.mas_top).offset(12);
        make.width.height.mas_equalTo(32);
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self installMovieNotificationObservers];
    [self.player prepareToPlay];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.player shutdown];
    [self removeMovieNotificationObservers];
    [self stopLive];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.isRecording = NO;
    self.isLiving = NO;
    self.navigationView.userInteractionEnabled = YES;
    [self addNavigationButton];
    self.backView.userInteractionEnabled = YES;
    
#ifdef DEBUG
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
    
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
    // [IJKFFMoviePlayerController checkIfPlayerVersionMatch:YES major:1 minor:0 micro:0];
    
    IJKFFOptions * options = [IJKFFOptions optionsByDefault];
    [options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT    forKey:@"skip_loop_filter"];
    [options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT    forKey:@"skip_frame"];
    
    self.url = [NSURL URLWithString:@"rtsp://192.168.42.1/live"];//http://live.hkstv.hk.lxdns.com/live/hks/playlist.m3u8
    
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.url withOptions:options];
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.player.view.frame = self.view.bounds;
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = YES;
    
    self.view.autoresizesSubviews = NO;
    [self.view insertSubview:self.player.view atIndex:0];
    
    //用MD360来全景渲染
    [self createVRLibrary];
    
#pragma mark url
    
    // 路径
    //    NSString *documents = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    //    // 最终合成输出路径
    //    NSString *outPutFilePath = [documents stringByAppendingPathComponent:@"merge.mp4"];
    //    _recordingURL = [[NSURL alloc] initFileURLWithPath:outPutFilePath];
    
    NSString *documentsDirPath =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSURL *documentsDirUrl = [NSURL fileURLWithPath:documentsDirPath isDirectory:YES];
    _recordingURL = [NSURL URLWithString:@"video.mp4" relativeToURL:documentsDirUrl];
    
    //    _recordingURL = [[NSURL alloc] initFileURLWithPath:[NSString pathWithComponents:@[NSTemporaryDirectory(), @"Movie.MOV"]]];
    _sessionQueue = dispatch_queue_create( "com.apple.sample.capturepipeline.session", DISPATCH_QUEUE_SERIAL );
    _videoDataOutputQueue = dispatch_queue_create( "com.apple.sample.capturepipeline.video", DISPATCH_QUEUE_SERIAL );
    dispatch_set_target_queue( _videoDataOutputQueue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 ) );
    
    
    self.timeLabel.text = @"00:15";
    self.msSeconds = 450;
    
    [self.progressView addSubview:self.progress];
    [self.progress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.progressView);
    }];
    
    self.swipeGestureType = SwipeGestureTypeLeft;
    if (self.swipeGestureType == SwipeGestureTypeLeft) {
        [self.videoButton setImage:[UIImage imageNamed:@"paishe_button_camera"] forState:UIControlStateNormal];
        [self.photoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_camera_sel"] forState:UIControlStateNormal];
        [self.videoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_videocamera_dis"] forState:UIControlStateNormal];
        [self.livingStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_tuiliu_dis"] forState:UIControlStateNormal];
        self.timeLabel.hidden = YES;
        self.progressView.hidden = YES;
    } else if (self.swipeGestureType == SwipeGestureTypeMiddle) {
        [self.videoButton setImage:[UIImage imageNamed:@"paishe_buttong_video_nor"] forState:UIControlStateNormal];
        [self.photoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_camera_dis"] forState:UIControlStateNormal];
        [self.videoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_videocamera_sel"] forState:UIControlStateNormal];
        [self.livingStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_tuiliu_dis"] forState:UIControlStateNormal];
        self.timeLabel.hidden = NO;
        self.progressView.hidden = NO;
    } else {
        [self.videoButton setImage:[UIImage imageNamed:@"paishe_buttong_video_nor"] forState:UIControlStateNormal];
        [self.photoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_camera_dis"] forState:UIControlStateNormal];
        [self.videoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_videocamera_dis"] forState:UIControlStateNormal];
        [self.livingStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_tuiliu_sel"] forState:UIControlStateNormal];
        self.timeLabel.hidden = YES;
        self.progressView.hidden = YES;
    }
}

#pragma Selector func

- (void)loadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"LoadStateDidChange: IJKMovieLoadStatePlayThroughOK: %d\n",(int)loadState);
    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackFinish:(NSNotification*)notification {
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    NSLog(@"mediaIsPrepareToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    switch (_player.playbackState) {
        case IJKMPMoviePlaybackStateStopped:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePlaying:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePaused:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateInterrupted:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
            
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

#pragma Install Notifiacation

- (void)installMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
    
}

- (void)removeMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:_player];
    
}

//MD360渲染
- (void) createVRLibrary{
    /////////////////////////////////////////////////////// MDVRLibrary
    MDVRConfiguration* config = [MDVRLibrary createConfig];
    
    MDVideoFrameAdapter *videoFrameAdapter = [MDIJKAdapter wrap:self.player.view];
    videoFrameAdapter.delegate = self;
    [config asVideoWithYUV420PProvider:videoFrameAdapter];
    //    [config asVideoWithYUV420PProvider:[MDIJKAdapter wrap:self.player.view]];
    [config setContainer:self view:self.view];
    // optional
    [config displayMode:MDModeDisplayNormal];
    [config projectionMode:MDModeProjectionSphere];
    [config interactiveMode:MDModeInteractiveMotionWithTouch];
    [config pinchEnabled:true];
    
    self.vrLibrary = [config build];
    /////////////////////////////////////////////////////// MDVRLibrary
}

//拍照
- (void)getVideoBufferForPhoto:(CVPixelBufferRef)pixelBuffer
{
    if (self.photoMark) {
        self.photoMark = NO;
        UIImage * photoImage = [self UIImageFromPixelBuffer:pixelBuffer];
        UIImageWriteToSavedPhotosAlbum(photoImage, nil, nil, nil);
    }
}

//拿到每一帧视频原始数据（YUV）
- (void)didGetPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (self.starLiveMark) {
        //推流（视频）
        [self.session pushVideo:pixelBuffer];
    }
    
    //录视频（视频）
    [self getVideoBuffer:pixelBuffer];
    //拍照
    [self getVideoBufferForPhoto:pixelBuffer];
}

//拿到每一帧音频原始数据（PCM）
- (void)didGetAudioData:(void *const)audioData lineSize:(int)linesize
{
    if (self.starLiveMark) {
        //推流（音频）
        NSData *data = [NSData dataWithBytes:audioData length:linesize];
        [self.session pushAudio:data];
    }
    
    //录视频（音频）
    [self getAudioSampleBuffer:[self createAudioSample:audioData frames:linesize]];
}

//开始推流直播
- (void)startLive {
        LFLiveStreamInfo *streamInfo = [LFLiveStreamInfo new];
        streamInfo.url = @"rtmp://push1.hongshiyun.net/live/c86f1omm_766a397a";//@"rtmp://push1.hongshiyun.net/live/c86f1omm_e2e0bad9";//@"rtmp://172.23.21.107:1935/rtmplive/room";
        [self.session startLive:streamInfo];
}

//停止推流
- (void)stopLive {
    [self.session stopLive];
}

#pragma Living 以下是推流初始化************************************
- (LFLiveSession*)session {
    if (!_session) {
        LFLiveVideoConfiguration * videoConfig = [LFLiveVideoConfiguration new];
        videoConfig.videoFrameRate = 30;
        videoConfig.videoMaxFrameRate = 30;
        videoConfig.videoMinFrameRate = 15;
        videoConfig.videoBitRate = 1200 * 1000;
        videoConfig.videoMaxBitRate = 1440 * 1000;
        videoConfig.videoMinBitRate = 800 * 1000;
        videoConfig.videoSize = CGSizeMake(1280, 720);
        videoConfig.videoMaxKeyframeInterval = 30 * 2;
        
        LFLiveAudioConfiguration * audioConfig = [LFLiveAudioConfiguration defaultConfigurationForQuality:LFLiveAudioQuality_High];
        audioConfig.numberOfChannels = 1;
        audioConfig.audioSampleRate = LFLiveAudioSampleRate_44100Hz;
        audioConfig.audioBitrate = LFLiveAudioBitRate_128Kbps;
        
        _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfig videoConfiguration:videoConfig captureType:LFLiveInputMaskAll];
        _session.showDebugInfo = YES;
        //        _session.adaptiveBitrate = YES;
        _session.delegate = self;
        _session.running = YES;
    }
    return _session;
}

- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange:(LFLiveState)state {
    NSLog(@"");
}

- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug *)debugInfo {
    NSLog(@"");
}

- (void)liveSession:(nullable LFLiveSession *)session errorCode:(LFLiveSocketErrorCode)errorCode {
    NSLog(@"");
}

#pragma start RECORD 以下是录视频************************************

//开始录视频
- (void)startRECORD
{
    NSLog(@"********* START");
    
    self.recorder = [[MovieRecorder alloc] initWithURL:_recordingURL];
    [self.recorder addAudioTrackWithSourceFormatDescription:self.outputAudioFormatDescription settings:nil];
    CGAffineTransform videoTransform = [self transformFromVideoBufferOrientationToOrientation:(AVCaptureVideoOrientation)UIDeviceOrientationPortrait withAutoMirroring:NO]; // Front camera recording shouldn't be mirrored
    
    [self.recorder addVideoTrackWithSourceFormatDescription:self.outputVideoFormatDescription transform:videoTransform settings:nil];
    
    dispatch_queue_t callbackQueue = dispatch_queue_create( "com.apple.sample.capturepipeline.recordercallback", DISPATCH_QUEUE_SERIAL ); // guarantee ordering of callbacks with a serial queue
    [self.recorder setDelegate:self callbackQueue:callbackQueue];
//    self.recorder = recorder;
    
    [self.recorder prepareToRecord]; // asynchronous, will call us back with recorderDidFinishPreparing: or recorder:didFailWithError: when done
}

//停止录视频
- (void)stopRecording
{
    NSLog(@"********* STOP");
    mvSTATE = 0;
    [self.recorder finishRecording]; // asynchronous, will call us back with recorderDidFinishRecording: or recorder:didFailWithError: when done
    self.recorder = nil;
}

//录视频，处理拿到的视频帧
- (void)getVideoBuffer:(CVPixelBufferRef)pixelBufferRef
{
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBufferRef, &videoInfo);
    self.outputVideoFormatDescription = videoInfo;
    if (mvSTATE ==1 ) {
        self.m_frameCount += 1;
        CMTime presentationTime = {0};
        presentationTime.timescale = 30;
        presentationTime.value = self.m_frameCount;
        presentationTime.flags = kCMTimeFlags_Valid;
        [self.recorder appendVideoPixelBuffer:pixelBufferRef withPresentationTime:presentationTime];
    }
    CFRelease(videoInfo);
}

//录视频，处理拿到的音频帧
- (void)getAudioSampleBuffer:(CMSampleBufferRef)sampleBufferRef
{
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBufferRef);
    self.outputAudioFormatDescription = formatDescription;
    if (mvSTATE ==1 ) {
        [self.recorder appendAudioSampleBuffer:sampleBufferRef];
    }
    CFRelease(sampleBufferRef);
}

- (void)movieRecorderDidFinishPreparing:(MovieRecorder *)recorder
{
    NSLog(@"开始准备录制。。。");
    mvSTATE = 1;
}

- (void)movieRecorder:(MovieRecorder *)recorder didFailWithError:(NSError *)error
{
    NSLog(@"录制错误。。。%@",error);
    mvSTATE = 0;
}

- (void)movieRecorderDidFinishRecording:(MovieRecorder *)recorder
{
    NSLog(@"录制结束。。。");
    self.recorder = nil;
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:_recordingURL completionBlock:^(NSURL *assetURL, NSError *error) {
        
        [[NSFileManager defaultManager] removeItemAtURL:_recordingURL error:NULL];
        
    }];
    
//    UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([_recordingURL absoluteString]);
}

#pragma mark Utilities

// Auto mirroring: Front camera is mirrored; back camera isn't
- (CGAffineTransform)transformFromVideoBufferOrientationToOrientation:(AVCaptureVideoOrientation)orientation withAutoMirroring:(BOOL)mirror
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // Calculate offsets from an arbitrary reference orientation (portrait)
    CGFloat orientationAngleOffset = angleOffsetFromPortraitOrientationToOrientation( orientation );
    CGFloat videoOrientationAngleOffset = angleOffsetFromPortraitOrientationToOrientation( self.videoOrientation );
    
    // Find the difference in angle between the desired orientation and the video orientation
    CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
    transform = CGAffineTransformMakeRotation( angleOffset );
    
    if ( _videoDevice.position == AVCaptureDevicePositionFront )
    {
        if ( mirror ) {
            transform = CGAffineTransformScale( transform, -1, 1 );
        }
        else {
            if ( UIInterfaceOrientationIsPortrait( orientation ) ) {
                transform = CGAffineTransformRotate( transform, M_PI );
            }
        }
    }
    
    return transform;
}

static CGFloat angleOffsetFromPortraitOrientationToOrientation(AVCaptureVideoOrientation orientation)
{
    CGFloat angle = 0.0;
    
    switch ( orientation )
    {
        case AVCaptureVideoOrientationPortrait:
            angle = 0.0;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        default:
            break;
    }
    
    return angle;
}

- (CMSampleBufferRef)createAudioSample:(void *)audioData frames:(UInt32)len

{
    int channels = 1;//2;
    
    AudioBufferList audioBufferList;
    audioBufferList.mNumberBuffers = 1;
    audioBufferList.mBuffers[0].mNumberChannels=channels;
    audioBufferList.mBuffers[0].mDataByteSize=len;
    audioBufferList.mBuffers[0].mData = audioData;
    
    AudioStreamBasicDescription asbd = [self getAudioFormat];
    
    CMSampleBufferRef buff = NULL;
    
    static CMFormatDescriptionRef format = NULL;
    
    CMTime time = CMTimeMake(len/2 , 44100);
    
    CMSampleTimingInfo timing = {CMTimeMake(1,44100), time, kCMTimeInvalid };
    
    OSStatus error = 0;
    
    if(format == NULL)
        
        error = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &asbd, 0, NULL, 0, NULL, NULL, &format);
    
    error = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, len/(2*channels), 1, &timing, 0, NULL, &buff);
    
    if ( error ) {
        NSLog(@"CMSampleBufferCreate returned error: %ld", (long)error);
        return NULL;
    }
    
    error = CMSampleBufferSetDataBufferFromAudioBufferList(buff, kCFAllocatorDefault, kCFAllocatorDefault, 0, &audioBufferList);
    
    if( error )
    {
        NSLog(@"CMSampleBufferSetDataBufferFromAudioBufferList returned error: %ld", (long)error);
        return NULL;
    }
    
    return buff;
}

-(AudioStreamBasicDescription) getAudioFormat{
    
    AudioStreamBasicDescription format;
    
    format.mSampleRate = 44100;
    
    format.mFormatID = kAudioFormatLinearPCM;
    
    format.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger;
    
    format.mBytesPerPacket = 2;//*2;
    
    format.mFramesPerPacket = 1;
    
    format.mBytesPerFrame = 2;//*2;
    
    format.mChannelsPerFrame = 1;//2;
    
    format.mBitsPerChannel = 16;
    
    format.mReserved = 0;
    
    return format;
}

- (UIImage*)UIImageFromPixelBuffer:(CVPixelBufferRef)p {
    CIImage* ciImage = [CIImage imageWithCVPixelBuffer:p];
    
    CIContext* context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}];
    
    CGRect rect = CGRectMake(0, 0, CVPixelBufferGetWidth(p), CVPixelBufferGetHeight(p));
    CGImageRef videoImage = [context createCGImage:ciImage fromRect:rect];
    
    UIImage* image = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    
    return image;
}

- (IBAction)changeStatusButton:(id)sender {
    //正在录像或者直播的时候不能切换，暂停直播或暂停录像才能滑动
    if (self.isRecording == YES || self.isLiving == YES) {
        return;
    }
    if (sender == self.photoStatusBtn) {
        //拍照
        [self.videoButton setImage:[UIImage imageNamed:@"paishe_button_camera"] forState:UIControlStateNormal];
        [self.photoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_camera_sel"] forState:UIControlStateNormal];
        [self.videoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_videocamera_dis"] forState:UIControlStateNormal];
        [self.livingStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_tuiliu_dis"] forState:UIControlStateNormal];
        self.swipeGestureType = SwipeGestureTypeLeft;
        self.timeLabel.hidden = YES;
        self.progressView.hidden = YES;
    } else if (sender == self.videoStatusBtn) {
        //录像
        [self.videoButton setImage:[UIImage imageNamed:@"paishe_buttong_video_nor"] forState:UIControlStateNormal];
        [self.photoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_camera_dis"] forState:UIControlStateNormal];
        [self.videoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_videocamera_sel"] forState:UIControlStateNormal];
        [self.livingStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_tuiliu_dis"] forState:UIControlStateNormal];
        self.swipeGestureType = SwipeGestureTypeMiddle;
        self.timeLabel.hidden = NO;
        self.progressView.hidden = NO;
    } else {
        //直播
        [self.videoButton setImage:[UIImage imageNamed:@"paishe_buttong_video_nor"] forState:UIControlStateNormal];
        [self.photoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_camera_dis"] forState:UIControlStateNormal];
        [self.videoStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_videocamera_dis"] forState:UIControlStateNormal];
        [self.livingStatusBtn setImage:[UIImage imageNamed:@"paishe_icon_tuiliu_sel"] forState:UIControlStateNormal];
        self.swipeGestureType = SwipeGestureTypeRight;
        self.timeLabel.hidden = YES;
        self.progressView.hidden = YES;
    }
}

//普通模式下拍照保存到APP本地和系统相册
- (void)takePhotoWithCommonModel
{
    self.photoMark = YES;
}

//普通模式下录制15秒的视频保存到APP本地和系统相册
- (void)recordVideoWithCommonModel
{
    //开启定时器
    [self.progressTimer setFireDate:[NSDate distantPast]];
//    self.progress
    
    [self startRECORD];
}

//普通模式下停止录视频
- (void)stopRecordVideoWithCommonModel
{
    [self stopRecording];
    [self.progressTimer invalidate];
    self.progressTimer = nil;
    self.isRecording = NO;
    [self.videoButton setImage:[UIImage imageNamed:@"paishe_buttong_video_nor"] forState:UIControlStateNormal];
    self.timeLabel.text = @"00:15";
    self.msSeconds = 450;
//    [self.progress setProgress:0 animated:YES];
    self.progress.progress = 0.f;
}


- (IBAction)videoButton:(id)sender {
    if (self.swipeGestureType == SwipeGestureTypeLeft) {
        [self takePhotoWithCommonModel];
    } else if (self.swipeGestureType == SwipeGestureTypeMiddle) {
        if (self.isRecording == NO) {
            [self recordVideoWithCommonModel];
            self.isRecording = YES;
            [self.videoButton setImage:[UIImage imageNamed:@"paishe_button_video_sel"] forState:UIControlStateNormal];
        } else {
            [self stopRecordVideoWithCommonModel];
        }
    } else {
        if (self.isLiving == NO) {
            NSLog(@"开始直播");
            self.starLiveMark = YES;
            [self startLive];
            [self.videoButton setImage:[UIImage imageNamed:@"paishe_button_video_sel"] forState:UIControlStateNormal];
            self.isLiving = YES;
        } else {
            self.starLiveMark = NO;
            [self stopLive];
            [self.videoButton setImage:[UIImage imageNamed:@"paishe_buttong_video_nor"] forState:UIControlStateNormal];
            self.isLiving = NO;
        }
    }
}

- (NSTimer *)progressTimer
{
    if (_progressTimer == nil) {
        _progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30
                                                        target:self
                                                      selector:@selector(progressTimer:)
                                                      userInfo:nil
                                                       repeats:YES];
    }
    return _progressTimer;
}

- (void)progressTimer:(NSTimer *)timer
{
    self.msSeconds--;
    if (self.msSeconds == 0) {
        [self stopRecordVideoWithCommonModel];
    }
    self.progress.progress += 1.0/450;
    if (self.msSeconds % 30 == 0) {
        if (self.msSeconds/30 < 10) {
            self.timeLabel.text = [NSString stringWithFormat:@"00:0%ld",(long)self.msSeconds/30];
        } else {
            self.timeLabel.text = [NSString stringWithFormat:@"00:%ld",(long)self.msSeconds/30];
        }
    }
}


//- (IBAction)StartSeesion:(id)sender {
////    DLog(@"%zd",[AeeCameraService.sharedAEECameraService connectToHost]);
////    [AeeCameraService.sharedAEECameraService aeeStartSeesion];
//    [self startLive];
//}
//
//- (IBAction)StopSeesion:(id)sender {
////    [AeeCameraService.sharedAEECameraService aeeStopSeesion];
//    [self stopLive];
//}

- (void)backButton:(UIButton *)sender {
    [_nextFrameTimer invalidate];
    _nextFrameTimer = nil;
    [_progressTimer invalidate];
    _progressTimer = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (UIProgressView *)progress
{
    if (_progress == nil) {
        _progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progress.progress = 0;
        _progress.progressTintColor = mRGBColor(228, 54, 74);
        _progress.trackTintColor = mRGBAColor(238, 238, 238, 0.5);
        [_progress setProgress:0 animated:YES];
    }
    return _progress;
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
