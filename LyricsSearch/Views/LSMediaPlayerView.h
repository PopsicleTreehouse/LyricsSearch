//
//  LSMediaPlayerView.h
//  LyricsSearch
//
//  Created by Brandon Yao on 5/11/22.
//

@import MarqueeLabel_ObjC;
#import <UIKit/UIKit.h>
#import "LSTrackItem.h"
#import "LSPlayerModel.h"
#import "LSTrackPresenter.h"

@interface LSMediaPlayerView : UIView
@property (nonatomic, strong) LSTrackItem *currentItem;
@property (nonatomic, strong) LSPlayerModel *playerModel;
- (instancetype)initWithPlayerModel:(LSPlayerModel *)playerModel;
- (void)connectedToSpotify;
- (void)disconnectedFromSpotify;
- (void)setCurrentItem:(LSTrackItem *)currentItem;
- (void)setElapsedTime:(NSInteger)elapsedTime;
- (void)setPlaybackState:(BOOL)paused;
- (void)playbackEnded;
- (void)trackChanged;
@end
