#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VideoPlayerViewDelegate <NSObject>

@optional
- (void)didUpdateTimeWithCurrentTimeInSecond:(long)currentTime totalTimeInSecond:(long)totalTime progress:(float)progress;
- (void)didUpdateTimeForThumbWithCurrentTimeInSecond:(long)currentTime totalTimeInSecond:(long)totalTime progress:(float)progress;
- (void)didUpdateBufferStatusWithIsBuffering:(BOOL)isBuffring;
- (void)didUpdateStatusWithStatus:(AVPlayerItemStatus)status;
- (void)didUpdatePlayerStatusWithNotificationName:(NSString *)notificationName;

@end

@interface VideoPlayerView : UIView

@property (strong, nonatomic) id<VideoPlayerViewDelegate> delegate;

- (void)setVideoWithUrl:(NSURL *)videoUrl;
- (BOOL)isPlayingVideo;
- (void)playVideo;
- (void)pauseVideo;
- (void)stopVideo;
- (void)cleanUpVideoPlayer;
- (void)videoForward;
- (void)videoBackword;
- (void)seekVideoToWithProgress:(float)progress;
- (UIImage *)getVideoThumbWithProgress:(float)progress;
- (void)getVideoThumbWithProgress:(float)progress complition:(void (^) (NSError *error, UIImage *image))complition;
- (AVPlayerItemStatus)getPlayerStatus;
- (NSString *)getErrorMessage;
- (void)didUpdateTimerTick;
- (void)updatedThumbTimeWithProgress:(float)progress;

@end

NS_ASSUME_NONNULL_END
