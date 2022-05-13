//
//  LSPlayerModel.m
//  LyricsSearch
//
//  Created by Brandon Yao on 5/7/22.
//

#import "LSPlayerModel.h"

@interface LSPlayerModel ()
@property (nonatomic, strong) LSTrackQueue *trackQueue;
@property (nonatomic, assign) NSInteger trackDuration;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation LSPlayerModel
//+ (instancetype)sharedPlayer {
//    static dispatch_once_t pred = 0;
//    static LSPlayerModel *_sharedPlayer = nil;
//    dispatch_once(&pred, ^{
//        _sharedPlayer = [[self alloc] init];
//    });
//    return _sharedPlayer;
//}
- (instancetype)initWithTrackQueue:(LSTrackQueue *)trackQueue {
    if(self = [super init]) {
        self.trackQueue = trackQueue;
    }
    return self;
}
- (NSArray *)nextTracks {
    return [self.trackQueue.nextTracks copy];
}
- (NSArray *)previousTracks {
    return [self.trackQueue.previousTracks copy];
}
- (void)setPaused:(BOOL)paused {
    _paused = paused;
    if(paused) [self.timer invalidate];
    else [self beginTimer];
}
- (void)timerFired {
    if(!self.shouldUpdate) return;
    self.elapsedTime += 10;
    if(self.elapsedTime >= self.trackDuration) {
        [self trackEnded];
        return;
    }
}
- (void)beginTimer {
    self.shouldUpdate = YES;
    self.timer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}
- (void)resetTimer {
    self.shouldUpdate = NO;
    [self.timer invalidate];
    self.elapsedTime = 0;
}
- (void)restartTimer {
    [self resetTimer];
    [self beginTimer];
}
- (LSTrackItem *)currentItem {
    return self.trackQueue.currentTrack;
}
- (void)setCurrentItem:(LSTrackItem *)currentItem {
    self.trackQueue.currentTrack = currentItem;
    [self resetPlayerForTrack:currentItem];
}
- (void)resetPlayerForTrack:(LSTrackItem *)track {
    if(!track) {
        [self resetTimer];
        return;
    }
    [self restartTimer];
    self.trackDuration = track.duration * 1000;
}
- (void)enqueue:(LSTrackItem *)trackItem {
    [self.trackQueue enqueue:trackItem];
}
- (void)trackEnded {
    [self playNextTrack];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"trackEnded" object:nil];
}
- (void)playNextTrack {
    [self.trackQueue increment];
    [self resetPlayerForTrack:self.currentItem];
}
- (void)playPreviousTrack {
    [self.trackQueue decrement];
    [self resetPlayerForTrack:self.currentItem];
}
@end
