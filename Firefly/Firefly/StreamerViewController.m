//
//  StreamerViewController.m
//  Firefly
//
//  Created by kampfgnu on 4/29/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "StreamerViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

#import "NSManagedObject+ActiveRecord.h"
#import "AudioStreamer.h"
#import "Song.h"
#import "Playlist+Extensions.h"
#import "PlaylistItem.h"
#import "KGTimeConverter.h"

@interface StreamerViewController ()

- (void)destroyStreamer;
- (void)createStreamer;
- (void)playbackStateChanged:(NSNotification *)notification;
- (IBAction)sliderMoved:(UISlider *)slider;
- (void)play;
- (void)nextSong;
- (void)setPlaylistText;

@property (nonatomic, strong) NSMutableArray *songQueue;
@property (nonatomic, strong) UITableView *playlistTable;

@end

@implementation StreamerViewController

$synthesize(streamer);
$synthesize(currentSong);
$synthesize(songQueue);
$synthesize(playlistTable);

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
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    playButton.frame = CGRectMake(10, 5, 40, 40);
    [playButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    [playButton setTitle:@">" forState:UIControlStateNormal];
    [self.view addSubview:playButton];
    
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    nextButton.frame = CGRectMake(320 - 50, 5, 40, 40);
    [nextButton addTarget:self action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
    [nextButton setTitle:@"||" forState:UIControlStateNormal];
    [self.view addSubview:nextButton];
    
    playlistTable_ = [[UITableView alloc] initWithFrame:CGRectMake(0, 50, 320, 350) style:UITableViewStylePlain];
    playlistTable_.delegate = self;
    playlistTable_.dataSource = self;
    [self.view addSubview:playlistTable_];
    
    [self setPlaylistText];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)updateUI {
    [self.playlistTable reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.playlistTable reloadData];
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDataSource
////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 140;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[Playlist currentPlaylist] allPlaylistItemsSortedByQueuePosition].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *songCellIdentifier = @"SongCell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:songCellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:songCellIdentifier];
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:13];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        
//        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
//		[cell addGestureRecognizer:longPressGesture];
    }
    
    Playlist *currentPlaylist = [Playlist currentPlaylist];
    PlaylistItem *playlistItem = [[currentPlaylist allPlaylistItemsSortedByQueuePosition] objectAtIndex:indexPath.row];
    Song *song = playlistItem.song;
    cell.textLabel.text = song.title;
    
    KGTimeConverter *timeConverter = [KGTimeConverter timeConverterWithNumber:song.song_length];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Track: %i\nArtist: %@\nAlbum: %@\nGenre: %@\nFilename: %@\nDuration: %@", [song.track intValue], song.artist, song.album, song.genre, song.filename, timeConverter.timeString];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Playlist *currentPlaylist = [Playlist currentPlaylist];
    PlaylistItem *playlistItem = [[currentPlaylist allPlaylistItemsSortedByQueuePosition] objectAtIndex:indexPath.row];
    currentPlaylist.currentPlaylistItem = playlistItem;
    [currentPlaylist save];
    
    [self start];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Playlist *currentPlaylist = [Playlist currentPlaylist];
        PlaylistItem *playlistItem = [[currentPlaylist allPlaylistItemsSortedByQueuePosition] objectAtIndex:indexPath.row];
        if (playlistItem == currentPlaylist.currentPlaylistItem) currentPlaylist.currentPlaylistItem = nil;
        [playlistItem deleteEntity];
        [playlistItem save];
        
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark - AudioStreamer methods
////////////////////////////////////////////////////////////////////////

- (void)destroyStreamer {
	if (self.streamer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ASStatusChangedNotification object:self.streamer];
		[self.streamer stop];
        self.streamer = nil;
    }
}

- (void)createStreamer {
    [self destroyStreamer];
    
    [self setPlaylistText];
    
    Playlist *currentPlaylist = [Playlist currentPlaylist];
    Song *currentSong = currentPlaylist.currentPlaylistItem.song;
    if (currentSong == nil) return;
    
    NSString *urlString = [[NSString stringWithFormat:@"%@/databases/1/items/%i.mp3", kBaseUrl, [currentSong.song_id intValue]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"urlstring: %@", urlString);
	
	NSURL *url = [NSURL URLWithString:urlString];
	self.streamer = [[AudioStreamer alloc] initWithURL:url];
    
    if ([currentPlaylist.currentPlaylistItem.progress floatValue] > 0.f) [self.streamer setInitialStartPositionInPercent:[currentPlaylist.currentPlaylistItem.progress floatValue] totalFileLength: [currentSong.file_size intValue]];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChanged:) name:ASStatusChangedNotification object:self.streamer];
    
    [self.streamer start];
    
    [self.playlistTable reloadData];
}

- (void)playbackStateChanged:(NSNotification *)notification {
    [self setPlaylistText];
    
    NSLog(@"state: %@, stopreason: %@, error: %@", [AudioStreamer stringForState:self.streamer.state], [AudioStreamer stringForStopReason:self.streamer.stopReason], [AudioStreamer stringForErrorCode:self.streamer.errorCode]);
    
    if (self.streamer.state == AS_PAUSED || self.streamer.stopReason == AS_INTERRUPTION) {
        Playlist *currentPlaylist = [Playlist currentPlaylist];
        Song *song = currentPlaylist.currentPlaylistItem.song;
        float progress = (self.streamer.progress * 1000) / [song.song_length floatValue];
        currentPlaylist.currentPlaylistItem.progress = [NSNumber numberWithFloat:progress];
        [currentPlaylist.currentPlaylistItem save];
    }
    
    if (self.streamer.state == AS_STOPPED && self.streamer.stopReason == AS_STOPPING_EOF) {
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

- (void)start {
    [self createStreamer];
}

- (void)playNextSong {
    //if (self.songQueue.count == 0) return;
    
    //self.currentSong = [self.songQueue objectAtIndex:0];
    Playlist *currentPlaylist = [Playlist currentPlaylist];
    [currentPlaylist skipToPlaylistItem:YES];
    [self createStreamer];
    
    //[self.songQueue removeObject:self.currentSong];
}

- (void)setPlaylistText {
//    NSString *playlistText = self.currentSong.title;
//    for (Song *s in self.songQueue) {
//        playlistText = [playlistText stringByAppendingFormat:@"\n%@", s.title];
//    }
//    self.textView.text = playlistText;
    
    [self.playlistTable reloadData];
    
    Playlist *currentPlaylist = [Playlist currentPlaylist];
    Song *currentSong = currentPlaylist.currentPlaylistItem.song;
    if (currentSong != nil) {
        MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter defaultCenter]; 
        infoCenter.nowPlayingInfo = [NSDictionary dictionaryWithObjectsAndKeys:currentSong.title, MPMediaItemPropertyTitle,
         currentSong.artist, MPMediaItemPropertyArtist, currentSong.album, MPMediaItemPropertyAlbumTitle, nil];
    }
}

- (void)play {
    [self start];
}

- (void)nextSong {
    [self playNextSong];
}

- (void)pause {
    [self.streamer pause];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self.streamer pause];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                break;
            default:
                break;
        }
    }
}

@end
