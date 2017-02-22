//
//  MDVideoFrameAdapter.m
//  MDVRLibrary
//
//  Created by ashqal on 16/7/15.
//  Copyright © 2016年 asha. All rights reserved.
//

#import "MDVRHeader.h"


@interface MDVideoFrameAdapter()

@property (nonatomic,weak) id<YUV420PTextureCallback> callback;

@end

@implementation MDVideoFrameAdapter

- (void) onFrameAvailable:(MDVideoFrame*) frame pixelBuffer:(CVPixelBufferRef)pixelBuffer{
    if (self.callback != nil) {
        [self.callback texture:(MDVideoFrame*)frame];
        
        if ([self.delegate respondsToSelector:@selector(didGetPixelBuffer:)]) {
            [self.delegate didGetPixelBuffer:pixelBuffer];
        }
    }
}

- (void)getAudioData:(void *const)audioData lineSize:(NSUInteger)linesize
{
    if (self.callback != nil) {
        if ([self.delegate respondsToSelector:@selector(didGetAudioData:lineSize:)]) {
            [self.delegate didGetAudioData:audioData lineSize:linesize];
        }
    }
}

-(void) onProvideBuffer:(id<YUV420PTextureCallback>)callback{
    self.callback = callback;
}

@end
