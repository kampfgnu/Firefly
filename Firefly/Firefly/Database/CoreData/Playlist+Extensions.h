//
//  Playlist+Extensions.h
//  Firefly
//
//  Created by kampfgnu on 5/4/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "Playlist.h"

@class Song;
@class Folder;
@class PlaylistItem;

@interface Playlist (Extensions)

+ (Playlist *)currentPlaylist;

- (void)addSongToList:(Song *)song replace:(BOOL)replace;
- (void)addFolderToList:(Folder *)folder recursively:(BOOL)recursively replace:(BOOL)replace;
- (void)addFolderRecursively:(Folder *)folder;

- (NSArray *)allPlaylistItemsSortedByQueuePosition;


- (void)skipToPlaylistItem:(BOOL)toNext;

@end
