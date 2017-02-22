# ATijkplayeriOS
1、编译ijkPlayer，支持RTSP流媒体的拉流播放，当然也支持http等格式。2、加入了MD360Player4iOS，实现视频的全景渲染。3、加入MovieRecorder实现用实时拉过来的音视频数据进行录视频。4、加入LFLiveKit实现用拉流过来的原始音视频数据(YUV、PCM)进行推流直播。

注意：由于编译ijkPlayer打出来的静态包超过了100M，所以没有加到项目工程里一起传到GitHub上，需要各位同学自行去我的百度网盘下载，自行添加到项目里，否则无法运行。

用法：下载本demo，去我的网盘下载ijkPlayer的静态包，添加到工程里，在ZHCameraPreviewViewController.m文件里设置拉流或者视频源的URL，

self.url = [NSURL URLWithString:@"rtsp://192.168.42.1/live"]; 

推流的话需要设置推流地址：
- (void)startLive {
        LFLiveStreamInfo *streamInfo = [LFLiveStreamInfo new];
        streamInfo.url = @"rtmp://push1.hongshiyun.net/live/c86f1omm_766a397a";
        [self.session startLive:streamInfo];
}


欢迎反馈问题，有用的话请给颗星，谢谢。
