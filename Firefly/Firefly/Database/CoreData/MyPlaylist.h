//
//  MyPlaylist.h
//  Firefly
//
//  Created by kampfgnu on 5/2/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "Playlist.h"

@class Song;

@interface MyPlaylist : Playlist

+ (MyPlaylist *)playlistItemForSong:(Song *)song;
+ (Song *)songForPlaylistItem:(MyPlaylist *)playlist;
+ (MyPlaylist *)addSongToQueue:(Song *)song;
+ (void)replaceAndAddSong:(Song *)song;
+ (Song *)currentSong;
+ (MyPlaylist *)currentPlaylistItem;
+ (void)currentSongDidFinish;
+ (NSArray *)allItemsSortedByQueuePosition;
+ (void)setPlaylistToCurrent:(MyPlaylist *)playlist;

@end
