//
//  StreamerViewController.m
//  Firefly
//
//  Created by kampfgnu on 4/29/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "StreamerViewController.h"

#import "AudioStreamer.h"
#import "Song.h"

@interface StreamerViewController ()

- (void)destroyStreamer;
- (void)createStreamer;
- (void)playbackStateChanged:(NSNotification *)notification;
- (IBAction)sliderMoved:(UISlider *)slider;
- (void)nextSong;
- (void)setPlaylistText;

@property (nonatomic, strong) NSMutableArray *songQueue;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation StreamerViewController

$synthesize(streamer);
$synthesize(currentSong);
$synthesize(songQueue);
$synthesize(textView);

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.songQueue = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(60, 10, 320 - 120, 30)];
    [slider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:slider];

    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    nextButton.frame = CGRectMake(320 - 50, 5, 40, 40);
    [nextButton addTarget:self action:@selector(nextSong) forControlEvents:UIControlEventTouchUpInside];
    [nextButton setTitle:@">>" forState:UIControlStateNormal];
    [self.view addSubview:nextButton];
    
    textView_ = [[UITextView alloc] initWithFrame:CGRectMake(0, 50, 320, 350)];
    textView_.textColor = [UIColor blackColor];
    textView_.editable = NO;
    [self.view addSubview:textView_];
    
    [self setPlaylistText];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)destroyStreamer {
	if (self.streamer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ASStatusChangedNotification object:self.streamer];
		[self.streamer stop];
        self.streamer = nil;
    }
}

- (void)createStreamer {
//	if (self.streamer) {
//		return;
//	}
    
	[self destroyStreamer];
    
    [self setPlaylistText];
    
    NSString *urlString = [[NSString stringWithFormat:@"%@/databases/1/items/%i.mp3", kBaseUrl, [self.currentSong.song_id intValue]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"urlstring: %@", urlString);
	
	NSURL *url = [NSURL URLWithString:urlString];
	self.streamer = [[AudioStreamer alloc] initWithURL:url];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChanged:) name:ASStatusChangedNotification object:self.streamer];
    
    [self.streamer start];
}

- (void)playbackStateChanged:(NSNotification *)notification {
    [self setPlaylistText];
    
	if ([self.streamer isWaiting]) {

	}
	else if ([self.streamer isPlaying]) {

	}
	else if ([self.streamer isIdle]) {
//		[self destroyStreamer];
        [self playNextSong];
	}
	else if (self.streamer.state == AS_STOPPED) {
		[self playNextSong];
	}
}

- (IBAction)sliderMoved:(UISlider *)slider {
    if (self.streamer.duration) {
        NSLog(@"duration: %f", self.streamer.duration);
		double newSeekTime = slider.value * self.streamer.duration;
		[self.streamer seekToTime:newSeekTime];
	}
    else {
        [self createStreamer];
        double newSeekTime = slider.value * self.streamer.duration;
		[self.streamer seekToTime:newSeekTime];
    }
}

- (void)playSong:(Song *)song {
    [self.songQueue removeAllObjects];
    [self.songQueue addObject:song];
    [self setPlaylistText];
    
    [self playNextSong];
}

- (void)addSongToQueue:(Song *)song {
    [self.songQueue addObject:song];
    [self setPlaylistText];
    
    if (![self.streamer isPlaying]) {
        [self playNextSong];
    }
}

- (void)playNextSong {
    if (self.songQueue.count == 0) return;
    
    self.currentSong = [self.songQueue objectAtIndex:0];
    
    [self createStreamer];
    
    [self.songQueue removeObject:self.currentSong];
}

- (void)setPlaylistText {
    NSString *playlistText = self.currentSong.title;
    for (Song *s in self.songQueue) {
        playlistText = [playlistText stringByAppendingFormat:@"\n%@", s.title];
    }
    self.textView.text = playlistText;
}

- (void)nextSong {
    [self playNextSong];
}

@end
