//add UIView in your viewcontroller and set class to VideoPlayerView

- (void)viewDidLoad {
	//panGuester for add ability drag to change progress bar and cut video
	UIPanGestureRecognizer *panGuester = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    panGuester.delaysTouchesBegan = YES;
    panGuester.delaysTouchesEnded = YES;
	//progressThumbView is simple rounded view over progressbar that and it extended UIButton class
    self.progressThumbView.userInteractionEnabled = YES;
    [self.progressThumbView addGestureRecognizer:panGuester];
    self.panGuester = panGuester;
    [self.progressThumbView addTarget:self action:@selector(actionTapSelect) forControlEvents:UIControlEventPrimaryActionTriggered];
    self.progressThumbView.delegate = self;

	[self.yourVideoPlayerView setVideoWithUrl:videoUrl];
    [self.yourVideoPlayerView playVideo];
}

- (void)panGesture:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:sender.view];
    if (sender.state == UIGestureRecognizerStateBegan) {
		//1. Pause you video
		self.isStartVideoDragAndCut = YES;
        self.isAllowDragToCutVideo = YES; // for check video cutting is started
		self.progressViewOldProgress = self.progressView.progress;
    } else if(sender.state == UIGestureRecognizerStateChanged) {
        if(self.isAllowDragToCutVideo) {
            float panAdjustmentValue = 0.25;
            CGFloat newProgress = panAdjustmentValue * (point.x / SCREEN_WIDTH);
            newProgress = self.progressViewOldProgress + newProgress;
            newProgress = fmin(1.0, newProgress);
            newProgress = fmax(0.0, newProgress);
            
            [self.progressView setProgress:newProgress animated:NO];
            self.progressThumbViewLeading.constant = (self.progressView.frame.size.width*newProgress) - 25.0f;
            [self.progressThumbView layoutIfNeeded];

			[self.yourVideoPlayerView updatedThumbTimeWithProgress:newProgress];            
            [self.yourVideoPlayerView getVideoThumbWithProgress:newProgress complition:^(NSError * _Nonnull error, UIImage * _Nonnull image) {
                if(error) {
                    PrintLog(@"Error:- %@", error.localizedDescription);
                } else if(image!=nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.yourthumbImage.image = image;
                    });
                }
            }];
        }
    } else if (sender.state == UIGestureRecognizerStateEnded) {
    } else {
    }
}

- (void)cancelPanguester {
    self.panGuester.enabled = NO;
    self.panGuester.enabled = YES;
    self.isAllowDragToCutVideo = NO;
    if(![self.yourVideoPlayerView isPlayingVideo]) {
		self.isStartVideoDragAndCut = NO;
		//play video
    }
}

#pragma mark - VideoPlayerViewDelegate

- (void)didUpdateTimeWithCurrentTimeInSecond:(long)currentTime totalTimeInSecond:(long)totalTime progress:(float)progress {
    if(self.isStartVideoDragAndCut) {return;}
    
    //Update Thumb position
    if(isnan(progress) || isinf(progress)) {
        progress = 0.0f;
    }
    [self.progressView setProgress:progress animated:NO];
    self.progressThumbViewLeading.constant = (self.progressView.frame.size.width*progress) - 25.0f; //-25 because round thumb size is 50
    [self.progressThumbView layoutIfNeeded];
}

- (void)didUpdateTimeForThumbWithCurrentTimeInSecond:(long)currentTime totalTimeInSecond:(long)totalTime progress:(float)progress {
	//update your player time
}

- (void)didUpdateBufferStatusWithIsBuffering:(BOOL)isBuffring {
    PrintLog(@"isBuffring : %d", isBuffring);
    if(isBuffring) {
        //start loader
    } else {
        //end loader
    }
}

- (void)didUpdateStatusWithStatus:(AVPlayerItemStatus)status {
    if(status==AVPlayerItemStatusReadyToPlay) {
        PrintLog(@"Status:- AVPlayerItemStatusReadyToPlay");
    } else if(status==AVPlayerItemStatusUnknown) {
        PrintLog(@"Status:- AVPlayerItemStatusUnknown");
    } else if(status==AVPlayerItemStatusFailed) {
        PrintLog(@"Status:- AVPlayerItemStatusFailed");
    }
}

- (void)didUpdatePlayerStatusWithNotificationName:(NSString *)notificationName {
    if([notificationName isEqualToString:AVPlayerItemDidPlayToEndTimeNotification]) {
        //Now you can close your player after finish video
    }
}
