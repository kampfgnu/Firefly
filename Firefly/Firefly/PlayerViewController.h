//
//  PlayerViewController.h
//  Firefly
//
//  Created by kampfgnu on 4/28/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@class Song;

@interface PlayerViewController : UIViewController

- (void)playSong:(Song *)song;
- (void)addSongToQueue:(Song *)song;
- (void)playNextSong;

@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;

@end
