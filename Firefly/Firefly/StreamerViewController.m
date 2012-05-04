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

#import "AudioStreamer.h"
#import "Song.h"
#import "MyPlaylist.h"
#import "KGTimeConverter.h"

@interface StreamerViewController ()

- (void)destroyStreamer;
- (void)createStreamer;
- (void)playbackStateChanged:(NSNotification *)notification;
- (IBAction)sliderMoved:(UISlider *)slider;
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

    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    nextButton.frame = CGRectMake(320 - 50, 5, 40, 40);
    [nextButton addTarget:self action:@selector(nextSong) forControlEvents:UIControlEventTouchUpInside];
    [nextButton setTitle:@">>" forState:UIControlStateNormal];
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
    return [MyPlaylist allItemsSortedByQueuePosition].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *folderCellIdentifier = @"FolderCell";
    static NSString *songCellIdentifier = @"SongCell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:(indexPath.section == 0) ? folderCellIdentifier : songCellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:(indexPath.section == 0) ? folderCellIdentifier : songCellIdentifier];
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:13];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
		[cell addGestureRecognizer:longPressGesture];
    }
    
    MyPlaylist *playlist = [[MyPlaylist allItemsSortedByQueuePosition] objectAtIndex:indexPath.row];
//    cell.textLabel.text = [NSString stringWithFormat:@"id: %i, current: %i", [playlist.song_id intValue], [playlist.isCurrentSong boolValue]];
    
    Song *song = [MyPlaylist songForPlaylistItem:playlist];
    cell.textLabel.text = song.title;
    
    KGTimeConverter *timeConverter = [KGTimeConverter timeConverterWithNumber:song.song_length];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Track: %i\nArtist: %@\nAlbum: %@\nGenre: %@\nFilename: %@\nDuration: %f", [song.track intValue], song.artist, song.album, song.genre, song.filename, timeConverter.timeString];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MyPlaylist *playlist = [[MyPlaylist allItemsSortedByQueuePosition] objectAtIndex:indexPath.row];
    
    [MyPlaylist setPlaylistToCurrent:playlist];
    [self start];
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
//	if (self.streamer) {
//		return;
//	}
    
	[self destroyStreamer];
    
    [self setPlaylistText];
    
    Song *currentSong = [MyPlaylist currentSong];
    if (currentSong == nil) return;
    
    NSString *urlString = [[NSString stringWithFormat:@"%@/databases/1/items/%i.mp3", kBaseUrl, [currentSong.song_id intValue]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"urlstring: %@", urlString);
	
	NSURL *url = [NSURL URLWithString:urlString];
	self.streamer = [[AudioStreamer alloc] initWithURL:url];
    NSLog(@"duration: %f", self.streamer.duration);
    MyPlaylist *playlist = [MyPlaylist playlistItemForSong:currentSong];
    if ([playlist.progress floatValue] > 0.f) [self.streamer setInitialStartPositionInPercent:[playlist.progress floatValue] totalFileLength: [currentSong.file_size intValue]];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChanged:) name:ASStatusChangedNotification object:self.streamer];
    
    [self.streamer start];
    
    [self.playlistTable reloadData];
}

- (void)playbackStateChanged:(NSNotification *)notification {
    [self setPlaylistText];
    
    NSLog(@"state: %@, stopreason: %@, error: %@", [AudioStreamer stringForState:self.streamer.state], [AudioStreamer stringForStopReason:self.streamer.stopReason], [AudioStreamer stringForErrorCode:self.streamer.errorCode]);
    
//    Song *currentSong = [MyPlaylist currentSong];
//    if (currentSong != nil) {
//        
//    }
    
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
    //if (self.songQueue.count == 0) return;
    
    //self.currentSong = [self.songQueue objectAtIndex:0];
    [MyPlaylist currentSongDidFinish];
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
    
    Song *currentSong = [MyPlaylist currentSong];
    if (currentSong != nil) {
        MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter defaultCenter]; 
        infoCenter.nowPlayingInfo = [NSDictionary dictionaryWithObjectsAndKeys:currentSong.title, MPMediaItemPropertyTitle,
         currentSong.artist, MPMediaItemPropertyArtist, currentSong.album, MPMediaItemPropertyAlbumTitle, nil];
    }
}

- (void)nextSong {
    [self playNextSong];
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
