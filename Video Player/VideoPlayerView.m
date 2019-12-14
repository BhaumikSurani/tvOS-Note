#import "VideoPlayerView.h"

@interface VideoPlayerView()
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) NSTimer *timerForCurrentVideoTime;
@property (strong, nonatomic) NSURL *videoUrl;
@property (strong, nonatomic) AVAsset *avAsset;
@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;
@end

@implementation VideoPlayerView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.player = [[AVPlayer alloc] init];
    //self.player.automaticallyWaitsToMinimizeStalling = NO;
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;//AVLayerVideoGravityResizeAspectFill;//UIViewContentModeScaleToFill;
    
    self.playerLayer.frame = self.layer.bounds;
    [self.layer addSublayer:self.playerLayer];
    
    /*[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceiver:) name:AVPlayerItemTimeJumpedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceiver:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceiver:) name:AVPlayerItemNewErrorLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceiver:) name:AVPlayerItemNewAccessLogEntryNotification object:nil];*/
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceiver:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceiver:) name:AVPlayerItemFailedToPlayToEndTimeErrorKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceiver:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)setVideoWithUrl:(NSURL *)videoUrl {
    self.videoUrl = videoUrl;
    //AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoUrl];
    
    self.avAsset = [AVAsset assetWithURL:videoUrl];
    self.imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:self.avAsset];
    self.imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    self.imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    self.imageGenerator.appliesPreferredTrackTransform = YES;
    //self.imageGenerator.maximumSize = CGSizeMake(240, 135);
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.avAsset];
    
    //self.player = [AVPlayer playerWithPlayerItem:playerItem];
    //self.player.volume = 2;
    if(self.player.currentItem) {
        if([self.delegate respondsToSelector:@selector(didUpdateBufferStatusWithIsBuffering:)]) {
            //remove observer for buffering
            [self.player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
            [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
            [self.player.currentItem removeObserver:self forKeyPath:@"playbackBufferFull"];
        }
        
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    }
    if([self.delegate respondsToSelector:@selector(didUpdateBufferStatusWithIsBuffering:)]) {
        //Add observer for buffering
        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceiver:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    
    [self.timerForCurrentVideoTime invalidate];
    self.timerForCurrentVideoTime = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(didUpdateTimerTick) userInfo:nil repeats:YES];
    
    /*if (@available(tvOS 10.0, *)) {
        [self.player.currentItem setPreferredForwardBufferDuration:5.0f];
        [self.player setAutomaticallyWaitsToMinimizeStalling:YES];
    }*/
}

- (void)refreshVideo {
    [self setVideoWithUrl:self.videoUrl];
}

- (BOOL)isPlayingVideo {
    return !(self.player.rate==0.0);
}

- (void)playVideo {
    if(self.player.currentItem.status==AVPlayerItemStatusFailed) {
        [self refreshVideo];
    } else {
        [self.player play];
    }
}

- (void)pauseVideo {
    [self.player pause];
}

- (void)stopVideo {
    [self.player seekToTime:CMTimeMake(0, 1)];
    [self.player pause];
}

- (AVPlayerItemStatus)getPlayerStatus {
    return self.player.currentItem.status;
}

- (NSString *)getErrorMessage {
    if(self.player.currentItem.error) {
        if(self.player.currentItem.error.code==NSURLErrorFileDoesNotExist) {
            return @"Video is not found.";
        } else if(self.player.currentItem.error.code == AVErrorFileFormatNotRecognized) {
            return @"This media format is not supported.";
        }
        return @"Load video fail.";
    }
    return @"";
}

- (void)cleanUpVideoPlayer {
    [self stopVideo];
    
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackBufferFull"];
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeErrorKey object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [self.timerForCurrentVideoTime invalidate];
    [self.playerLayer removeFromSuperlayer];
}

- (void)videoForward {
    CMTime currentTime = self.player.currentTime;
    currentTime.value = (((long)currentTime.value) + (((long)currentTime.timescale) * 10));
    [self.player seekToTime:currentTime];
}

- (void)videoBackword {
    CMTime currentTime = self.player.currentTime;
    currentTime.value = (((long)currentTime.value) - (((long)currentTime.timescale) * 10));
    [self.player seekToTime:currentTime];
}

- (void)notificationReceiver:(NSNotification*)notification {
    NSLog(@"Notificaiton name:- %@", notification.name);
    if([notification.name isEqualToString:AVPlayerItemDidPlayToEndTimeNotification]) {
        [self.player pause];
        [self.player seekToTime:kCMTimeZero];
    }
    
    if([self.delegate respondsToSelector:@selector(didUpdatePlayerStatusWithNotificationName:)]) {
        [self.delegate didUpdatePlayerStatusWithNotificationName:notification.name];
    }
}

- (void)seekVideoToWithProgress:(float)progress {
    CMTime durationTime = self.player.currentItem.duration;
    if(CMTIME_IS_INDEFINITE(durationTime)) {
        return;
    }
    durationTime.value = durationTime.value * progress;
    [self.player seekToTime:durationTime];
}

- (UIImage *)getVideoThumbWithProgress:(float)progress {
    //AVAsset *asset = [AVAsset assetWithURL:[NSURL URLWithString:self.videoUrl]];
    //AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    //imageGenerator.maximumSize = CGSizeMake(100, 100);
    //CMTime time = CMTimeMake(5, 1);//thumb at 5 second
    
    [self.imageGenerator cancelAllCGImageGeneration];
    CMTime time = self.player.currentItem.duration;
    time.value = time.value * progress;
    CGImageRef imageRef = [self.imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    return thumbnail;
}

- (void)getVideoThumbWithProgress:(float)progress complition:(void (^) (NSError *error, UIImage *image))complition {
    //Get thumb with async procress     
    [self.imageGenerator cancelAllCGImageGeneration];
    CMTime time = self.player.currentItem.duration;
    time.value = time.value * progress;
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:time]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        if(!error) {
            UIImage *imgThumb = [UIImage imageWithCGImage:image];
            complition(error, imgThumb);
        } else {
            complition(error, nil);
        }        
    }];
}

- (void)didReceiveNotification:(NSNotification *)notification {
    if([notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {
        [self.timerForCurrentVideoTime invalidate];
    } else if([notification.name isEqualToString:UIApplicationWillEnterForegroundNotification]) {
        [self.timerForCurrentVideoTime invalidate];
        self.timerForCurrentVideoTime = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(didUpdateTimerTick) userInfo:nil repeats:YES];
    }
}

#pragma mark - Buffering Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if([object isKindOfClass:[AVPlayerItem class]]) {
        if([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            // Show loader
            if([self.delegate respondsToSelector:@selector(didUpdateBufferStatusWithIsBuffering:)]) {
                [self.delegate didUpdateBufferStatusWithIsBuffering:YES];
            }
        } else if([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            // Hide loader
            if([self.delegate respondsToSelector:@selector(didUpdateBufferStatusWithIsBuffering:)]) {
                //[self.delegate didUpdateBufferStatusWithIsBuffering:NO];
                [self.delegate didUpdateBufferStatusWithIsBuffering:self.player.currentItem.playbackBufferEmpty ? YES : NO];
            }
        } else if([keyPath isEqualToString:@"playbackBufferFull"]) {
            // Hide loader
            if([self.delegate respondsToSelector:@selector(didUpdateBufferStatusWithIsBuffering:)]) {
                [self.delegate didUpdateBufferStatusWithIsBuffering:NO];
            }
        } else if([keyPath isEqualToString:@"status"]) {
            if ([self.delegate respondsToSelector:@selector(didUpdateStatusWithStatus:)]) {
                [self.delegate didUpdateStatusWithStatus:self.player.currentItem.status];
            }
        }
    }
}

#pragma mark - VideoPlayerViewDelegate

- (void)didUpdateTimerTick {
    if([self.delegate respondsToSelector:@selector(didUpdateTimeWithCurrentTimeInSecond:totalTimeInSecond:progress:)]) {
        CMTime durationTime = self.player.currentItem.duration;
        CMTime currentTime = self.player.currentTime;
        long currentTimeSecond = (currentTime.value/(float)currentTime.timescale);
        //NSLog(@"%@, %f, %f", durationTime, durationTime.value, durationTime.timescale);
        long totalTimeSecond = (durationTime.value/(float)durationTime.timescale);
        float progress = currentTimeSecond/(float)totalTimeSecond;
        //NSLog(@"Current Time:-%ld, Total Time:-%ld, Progress:-%0.4f", currentTimeSecond, totalTimeSecond, progress);
        
        /*NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
        if(loadedTimeRanges.count>0) {
            CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
            Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
            Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
            NSTimeInterval result = startSeconds + durationSeconds;
            NSLog(@"Bufferd Time:- %0.2f", result);
        }*/
        
        [self.delegate didUpdateTimeWithCurrentTimeInSecond:currentTimeSecond totalTimeInSecond:totalTimeSecond progress:progress];
    } else {
        [self.timerForCurrentVideoTime invalidate];
    }
}

- (void)updatedThumbTimeWithProgress:(float)progress {
    if([self.delegate respondsToSelector:@selector(didUpdateTimeForThumbWithCurrentTimeInSecond:totalTimeInSecond:progress:)]) {
        CMTime durationTime = self.player.currentItem.duration;
        long totalTimeSecond = (durationTime.value/(float)durationTime.timescale);
        long currentTimeSecond = totalTimeSecond * progress;
        [self.delegate didUpdateTimeForThumbWithCurrentTimeInSecond:currentTimeSecond totalTimeInSecond:totalTimeSecond progress:progress];
    }
}

@end
