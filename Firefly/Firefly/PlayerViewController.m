//
//  PlayerViewController.m
//  Firefly
//
//  Created by kampfgnu on 4/28/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "PlayerViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "Song.h"

@interface PlayerViewController ()

- (void)playbackStateDidChange:(NSNotification *)notification;
- (void)loadStateDidChange:(NSNotification *)notification;
- (void)playbackDidFinish:(NSNotification *)notification;
- (void)playerDurationAvailable:(NSNotification *)notification;

@property (nonatomic, strong) NSMutableArray *songQueue;

@end

@implementation PlayerViewController

$synthesize(moviePlayerController);
$synthesize(songQueue);

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        BOOL backgroundAudioInitialized = [self initBackgroundAudio];
        NSLog(@"backgroundAudioInitialized: %i", backgroundAudioInitialized);
        
        self.songQueue = [NSMutableArray array];
        
        self.moviePlayerController = [[MPMoviePlayerController alloc] init];
        self.moviePlayerController.useApplicationAudioSession = NO;
        self.moviePlayerController.shouldAutoplay = YES;
        self.moviePlayerController.view.frame = CGRectMake(10.f, 10.f, 300.f, 30.f);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:moviePlayerController_];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:moviePlayerController_];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:moviePlayerController_];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDurationAvailable:) name:MPMovieDurationAvailableNotification object:moviePlayerController_];
        
//        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
//        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
//        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMovieDurationAvailableNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.moviePlayerController.view];
}

- (BOOL)initBackgroundAudio {
	//for background audio
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	NSError *error = nil;
    
	// set audio-category and check for errors
	if (![audioSession setCategory:AVAudioSessionCategoryPlayback error:&error]) {
		// TODO: handle error
		NSLog(@"RBAudioHTTPSController::initBackgroundAudio: Unable to set Category of AudioSession: %@", error);
		return NO;
	}
    
	error = nil;
    
	if (![audioSession setActive:YES error:&error]) {
		// TODO: handle error
		NSLog(@"RBAudioHTTPSController::initBackgroundAudio: Unable to set AudioSession active: %@", error);
		return NO;
	}
    
	return YES;
}

- (void)playSong:(Song *)song {
    [self.songQueue removeAllObjects];
    [self.songQueue addObject:song];
    
    [self playNextSong];
}

- (void)addSongToQueue:(Song *)song {
    [self.songQueue addObject:song];
    
    if (self.moviePlayerController.playbackState != MPMoviePlaybackStatePlaying) {
        [self playNextSong];
    }
}

- (void)playNextSong {
    Song *song = [self.songQueue objectAtIndex:0];

    NSString *urlString = [NSString stringWithFormat:@"%@/databases/1/items/%i.mp3", kBaseUrl, [song.song_id intValue]];
    NSLog(@"urlstring: %@", urlString);
    
    [self.moviePlayerController setContentURL:[NSURL URLWithString:urlString]];
    [self.moviePlayerController play];
    
    [self.songQueue removeObject:song];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark - 
////////////////////////////////////////////////////////////////////////

- (void)playbackDidFinish:(NSNotification *)notification {
	if (self.songQueue.count > 0) {
        [self playNextSong];
    }
}

- (void)playbackStateDidChange:(NSNotification *)notification {
	MPMoviePlayerController *mp = [notification object];
	//BOOL isPlaying = (mp.playbackState == MPMoviePlaybackStatePlaying);
	
	NSLog(@"playbackStateDidChange: %i", mp.playbackState);	
}

- (void)loadStateDidChange:(NSNotification *)notification {
	MPMoviePlayerController *mp = [notification object];
	//DDLogInfo(@"loadStateDidChange: %@", [self playerLoadStateString:mp.loadState]);
	NSLog(@"errorLog %@", [[NSString alloc] initWithData:mp.errorLog.extendedLogData encoding:NSUTF8StringEncoding]);
	
    //	if (mp.loadState & MPMovieLoadStatePlayable || mp.loadState & MPMovieLoadStateStalled) {
    //		currentPlaybackPosition = mp.currentPlaybackTime;
    //		self.moviePlayerController.contentURL = [NSURL URLWithString:self.streamURL];
    //	}
    //	
    //	if (mp.playbackState & MPMovieLoadStatePlayable ||
    //		mp.playbackState & MPMovieLoadStatePlaythroughOK) {
    //		if (currentPlaybackPosition > 0) {
    //			mp.currentPlaybackTime = currentPlaybackPosition;
    //			currentPlaybackPosition = -1.;
    //		}
    //	}
}

- (void)playerDurationAvailable:(NSNotification *)notification {
	//#if DEBUG
	//	MPMoviePlayerController *mpMoviePlayer = [notification object];
	//	NSLog(@"duration: %f", mpMoviePlayer.duration);
	//#endif
	MPMoviePlayerController *mp = [notification object];
	//float progress = mpMoviePlayer.currentPlaybackTime/mpMoviePlayer.duration;
	NSTimeInterval duration = mp.duration;
	NSLog(@"duration available: %f", duration);
}

@end
