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

NS_ASSUME_NONNULL_BEGIN

@interface LSMediaPlayerView : UIView
@property (nonatomic, strong) LSTrackItem *currentItem;
- (void)beginObserving;
@end

NS_ASSUME_NONNULL_END
