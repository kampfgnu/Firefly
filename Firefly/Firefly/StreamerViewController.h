//
//  StreamerViewController.h
//  Firefly
//
//  Created by kampfgnu on 4/29/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

@class AudioStreamer;
@class Song;

@interface StreamerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) AudioStreamer *streamer;
@property (nonatomic, strong) Song *currentSong;

- (void)start;
- (void)updateUI;
- (void)playSong:(Song *)song;
- (void)addSongToQueue:(Song *)song;
- (void)playNextSong;
- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent;

@end
