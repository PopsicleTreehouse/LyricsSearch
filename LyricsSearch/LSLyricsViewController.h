//
//  LSLyricsViewController.h
//  LyricsSearch
//
//  Created by Brandon Yao on 4/20/22.
//

@import MarqueeLabel_ObjC;
#import <UIKit/UIKit.h>
#import "LSDataManager.h"
#import "LSLyricsTableViewController.h"
#import "LSPlayerModel.h"
#import "LSTrackItem.h"
#import "LSTrackQueue.h"

@interface LSLyricsViewController : UIViewController
- (instancetype)initWithLyrics:(NSArray *)lyrics song:(NSString *)song artist:(NSString *)artist image:(UIImage *)image duration:(NSInteger)duration;
//- (instancetype)initWithTrackItem:(LSTrackItem *)trackItem;
- (void)setPlayingTrack:(LSTrackItem *)track;
@end
