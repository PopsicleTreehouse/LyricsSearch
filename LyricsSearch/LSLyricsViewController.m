//
//  LSLyricsViewController.m
//  LyricsSearch
//
//  Created by Brandon Yao on 1/9/22.
//

#import "LSLyricsViewController.h"

@interface LSLyricsViewController ()
@property (nonatomic, strong) NSArray *lyrics;
@property (nonatomic, strong) NSString *song;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, strong) LSLyricsTableViewController *tableViewController;
@property (nonatomic, strong) MarqueeLabel *songLabel;
@property (nonatomic, strong) MarqueeLabel *artistLabel;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *controlsView;
@property (nonatomic, strong) UIButton *pauseButton;
@property (nonatomic, strong) UIButton *previousButton;
@property (nonatomic, strong) UIButton *skipButton;
@property (nonatomic, strong) UISlider *timeSlider;
@property (nonatomic, strong) UILabel *elapsedTimeLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) NSDate *dismissalDate;
@end

@implementation LSLyricsViewController

- (instancetype)initWithLyrics:(NSArray *)lyrics song:(NSString *)song artist:(NSString *)artist image:(UIImage *)image duration:(NSInteger)duration {
    if(self = [super init]) {
        self.lyrics = lyrics;
        self.song = song;
        self.artist = artist;
        self.backgroundImage = image;
        self.duration = duration;
        LSPlayerModel *sharedPlayer = [LSPlayerModel sharedPlayer];
        [sharedPlayer addObserver:self forKeyPath:@"elapsedTime" options:NSKeyValueObservingOptionNew context:nil];
        [sharedPlayer addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (instancetype)initWithTrackItem:(LSTrackItem *)trackItem {
    NSArray *lyrics = [LSDataManager lyricsForSong:trackItem.songName artist:trackItem.artistName];
    NSString *song = trackItem.songName;
    NSString *artist = trackItem.artistName;
    UIImage *image = trackItem.artImage;
    NSInteger duration = trackItem.duration;
    return [self initWithLyrics:lyrics song:song artist:artist image:image duration:duration];
}

- (void)dealloc {
    LSPlayerModel *sharedPlayer = [LSPlayerModel sharedPlayer];
    [sharedPlayer removeObserver:self forKeyPath:@"elapsedTime"];
    [sharedPlayer removeObserver:self forKeyPath:@"currentItem"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    id item = change[@"new"];
    if([keyPath isEqualToString:@"elapsedTime"]) {
        NSInteger elapsedTime = [item intValue];
        [self updateElapsedTime:elapsedTime];
    }
    if([keyPath isEqualToString:@"currentitem"]) {
        if([item isEqualToString:@"<null>"]) [self trackEnded];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableViewController = [[LSLyricsTableViewController alloc] initWithLyrics:self.lyrics];
    self.backgroundImageView = [[UIImageView alloc] initWithImage:self.backgroundImage];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundImageView addSubview:blurEffectView];
    [self.view addSubview:self.backgroundImageView];
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.containerView];
    self.songLabel = [[MarqueeLabel alloc] init];
    self.songLabel.marqueeType = MLLeftRight;
    self.songLabel.font = [UIFont systemFontOfSize:40 weight:UIFontWeightHeavy];
    self.songLabel.textColor = [UIColor whiteColor];
    self.songLabel.text = self.song;
    self.songLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.songLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:self.songLabel];
    self.artistLabel = [[MarqueeLabel alloc] init];
    self.artistLabel.marqueeType = MLLeftRight;
    self.artistLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightHeavy];
    self.artistLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    self.artistLabel.text = self.artist;
    self.artistLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.artistLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:self.artistLabel];
    self.controlsView = [[UIView alloc] init];
    self.controlsView.backgroundColor = [UIColor clearColor];
    self.controlsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.controlsView];
    UIImage *normalThumbImage = [UIImage imageNamed:@"ThumbImageNormal"];
    UIImage *highlightedThumbImage = [UIImage imageNamed:@"ThumbImageHighlighted"];
    self.timeSlider = [[UISlider alloc] init];
    self.timeSlider.maximumValue = self.duration;
    self.timeSlider.continuous = YES;
    self.timeSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeSlider.minimumTrackTintColor = [UIColor whiteColor];
    [self.timeSlider setThumbImage:normalThumbImage forState:UIControlStateNormal];
    [self.timeSlider setThumbImage:highlightedThumbImage forState:UIControlStateHighlighted];
    [self.timeSlider addTarget:self action:@selector(sliderDragged:forEvent:) forControlEvents:UIControlEventValueChanged];
    [self.controlsView addSubview:self.timeSlider];
    self.elapsedTimeLabel = [[UILabel alloc] init];
    self.elapsedTimeLabel.textColor = [UIColor grayColor];
    self.elapsedTimeLabel.text = @"0:00";
    self.elapsedTimeLabel.font = [UIFont fontWithName:@"Helvetica" size:11];
    self.elapsedTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlsView addSubview:self.elapsedTimeLabel];
    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.textColor = [UIColor grayColor];
    self.durationLabel.text = [NSString stringWithFormat:@"%ld:%02ld", self.duration / 60, self.duration % 60];
    self.durationLabel.font = [UIFont fontWithName:@"Helvetica" size:11];
    self.durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlsView addSubview:self.durationLabel];
    self.skipButton = [[UIButton alloc] init];
    [self.skipButton addTarget:self action:@selector(playNextTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.skipButton setImage:[UIImage imageNamed:@"SkipIcon"] forState:UIControlStateNormal];
    self.skipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlsView addSubview:self.skipButton];
    self.previousButton = [[UIButton alloc] init];
    [self.previousButton addTarget:self action:@selector(playPreviousTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.previousButton setImage:[UIImage imageNamed:@"PreviousIcon"] forState:UIControlStateNormal];
    self.previousButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlsView addSubview:self.previousButton];
    self.pauseButton = [[UIButton alloc] init];
    [self.pauseButton addTarget:self action:@selector(pauseButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.pauseButton setImage:[UIImage imageNamed:@"PauseIcon"] forState:UIControlStateNormal];
    self.pauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.controlsView addSubview:self.pauseButton];
    [self displayContentController:self.tableViewController];
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backgroundImageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.backgroundImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backgroundImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [blurEffectView.topAnchor constraintEqualToAnchor:self.backgroundImageView.topAnchor],
        [blurEffectView.bottomAnchor constraintEqualToAnchor:self.backgroundImageView.bottomAnchor],
        [blurEffectView.leadingAnchor constraintEqualToAnchor:self.backgroundImageView.leadingAnchor],
        [blurEffectView.trailingAnchor constraintEqualToAnchor:self.backgroundImageView.trailingAnchor],
        [self.containerView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:150],
        [self.containerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-130],
        [self.containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:25],
        [self.containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-25],
        [self.songLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:50],
        [self.songLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:self.tableViewController.tableView.contentInset.left + 25],
        [self.songLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-25],
        [self.artistLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:100],
        [self.artistLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:self.tableViewController.tableView.contentInset.left + 25],
        [self.artistLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-25],
        [self.controlsView.topAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],
        [self.controlsView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.controlsView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.controlsView.widthAnchor constraintEqualToConstant:330],
        [self.timeSlider.topAnchor constraintEqualToAnchor:self.controlsView.topAnchor constant:15],
        [self.timeSlider.centerXAnchor constraintEqualToAnchor:self.controlsView.centerXAnchor],
        [self.timeSlider.widthAnchor constraintEqualToAnchor:self.controlsView.widthAnchor constant:-20],
        [self.timeSlider.heightAnchor constraintEqualToConstant:10],
        [self.elapsedTimeLabel.topAnchor constraintEqualToAnchor:self.timeSlider.bottomAnchor constant:8],
        [self.elapsedTimeLabel.leadingAnchor constraintEqualToAnchor:self.timeSlider.leadingAnchor],
        [self.durationLabel.topAnchor constraintEqualToAnchor:self.timeSlider.bottomAnchor constant:8],
        [self.durationLabel.trailingAnchor constraintEqualToAnchor:self.timeSlider.trailingAnchor],
        [self.previousButton.leadingAnchor constraintEqualToAnchor:self.controlsView.leadingAnchor constant:30],
        [self.previousButton.centerYAnchor constraintEqualToAnchor:self.controlsView.centerYAnchor constant:10],
        [self.previousButton.heightAnchor constraintEqualToConstant:40],
        [self.previousButton.widthAnchor constraintEqualToConstant:40],
        [self.skipButton.trailingAnchor constraintEqualToAnchor:self.controlsView.trailingAnchor constant:-30],
        [self.skipButton.centerYAnchor constraintEqualToAnchor:self.controlsView.centerYAnchor constant:10],
        [self.skipButton.heightAnchor constraintEqualToConstant:40],
        [self.skipButton.widthAnchor constraintEqualToConstant:40],
        [self.pauseButton.centerXAnchor constraintEqualToAnchor:self.controlsView.centerXAnchor],
        [self.pauseButton.centerYAnchor constraintEqualToAnchor:self.controlsView.centerYAnchor constant:10],
        [self.pauseButton.heightAnchor constraintEqualToConstant:40],
        [self.pauseButton.widthAnchor constraintEqualToConstant:40],
    ]];
}

- (void)updateElapsedTime:(NSInteger)elapsedTime {
    [self.tableViewController updateElapsedTime:elapsedTime];
    NSInteger seconds = elapsedTime / 1000;
    [self updateElapsedTimeLabel:seconds];
    if(!self.timeSlider.isHighlighted) [self.timeSlider setValue:seconds animated:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    LSPlayerModel *sharedPlayer = [LSPlayerModel sharedPlayer];
    if(sharedPlayer.currentItem) {
        sharedPlayer.shouldUpdate = NO;
        self.dismissalDate = [NSDate now];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(self.dismissalDate) {
        LSPlayerModel *sharedPlayer = [LSPlayerModel sharedPlayer];
        NSInteger diff = self.dismissalDate.timeIntervalSinceNow * 1000;
        sharedPlayer.elapsedTime += diff;
        sharedPlayer.shouldUpdate = YES;
        self.dismissalDate = nil;
    }
}

- (void)updateElapsedTimeLabel:(NSInteger)time {
    NSInteger minutes = time / 60;
    NSInteger seconds = time % 60;
    NSString *timeString = [NSString stringWithFormat:@"%ld:%02ld", minutes, seconds];
    self.elapsedTimeLabel.text = timeString;
}

- (void)sliderDragged:(UISlider *)slider forEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    NSInteger selectedTime = slider.value * 1000;
    LSPlayerModel *sharedPlayer = [LSPlayerModel sharedPlayer];
    switch (touch.phase) {
        case UITouchPhaseBegan:
            sharedPlayer.shouldUpdate = NO;
            break;
        case UITouchPhaseMoved:
            [self.tableViewController updateTimestampForTime:selectedTime];
            sharedPlayer.elapsedTime = selectedTime;
            break;
        case UITouchPhaseEnded:
            sharedPlayer.shouldUpdate = YES;
            break;
        default:
            break;
    }
}

- (void)trackEnded {
    [self playNextTrack];
}

- (void)displayContentController:(UIViewController *)content {
    [self addChildViewController:content];
    [self.containerView addSubview:content.view];
    content.view.frame = self.containerView.bounds;
    [content didMoveToParentViewController:self];
}

- (void)dismissLyricsView {
    [[LSPlayerModel sharedPlayer] setCurrentItem:nil];
    [[LSTrackQueue sharedQueue] increment];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setPlayingTrack:(LSTrackItem *)track {
    LSPlayerModel *sharedPlayer = [LSPlayerModel sharedPlayer];
    [sharedPlayer setCurrentItem:track];
    [self.pauseButton setImage:[UIImage imageNamed:@"PauseIcon"] forState:UIControlStateNormal];
    if(!track) {
        [self dismissLyricsView];
        return;
    }
    self.dismissalDate = nil;
    self.duration = track.duration;
    self.timeSlider.maximumValue = self.duration;
    self.durationLabel.text = [NSString stringWithFormat:@"%ld:%02ld", self.duration / 60, self.duration % 60];
    self.backgroundImageView.image = track.artImage;
    self.artistLabel.text = track.artistName;
    self.songLabel.text = track.songName;
    self.elapsedTimeLabel.text = @"0:00";
    [self.tableViewController setPlayingTrack:track];
}

- (void)playNextTrack {
    LSTrackQueue *sharedQueue = [LSTrackQueue sharedQueue];
    if([sharedQueue.nextTracks count] == 0) {
        [self dismissLyricsView];
        return;
    }
    [sharedQueue increment];
    LSTrackItem *nextItem = [sharedQueue currentTrack];
    [self setPlayingTrack:nextItem];
}

- (void)playPreviousTrack {
    LSTrackQueue *sharedQueue = [LSTrackQueue sharedQueue];
    if([sharedQueue.previousTracks count] == 0) {
        [self dismissLyricsView];
        return;
    }
    [sharedQueue decrement];
    LSTrackItem *previousItem = [sharedQueue currentTrack];
    [self setPlayingTrack:previousItem];
}

- (void)pauseButtonPressed {
    LSPlayerModel *sharedPlayer = [LSPlayerModel sharedPlayer];
    if(sharedPlayer.paused) {
        [self.pauseButton setImage:[UIImage imageNamed:@"PauseIcon"] forState:UIControlStateNormal];
        sharedPlayer.paused = NO;
    }
    else {
        [self.pauseButton setImage:[UIImage imageNamed:@"PlayIcon"] forState:UIControlStateNormal];
        sharedPlayer.paused = YES;
    }
}
@end
