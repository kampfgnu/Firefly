//
//  MyPlaylist.m
//  Firefly
//
//  Created by kampfgnu on 5/2/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "MyPlaylist.h"
#import "NSManagedObject+ActiveRecord.h"
#import "NSManagedObjectContext+ActiveRecord.h"
#import "Song.h"

@interface MyPlaylist ()

@end


@implementation MyPlaylist

+ (MyPlaylist *)addSongToQueue:(Song *)song {
    MyPlaylist *playlist = [Playlist createEntity];
    playlist.song_id = song.song_id;
    playlist.isCurrentSong = [NSNumber numberWithBool:NO];
    playlist.progress = [NSNumber numberWithFloat:0.f];
    playlist.queue_position = [NSNumber numberWithInt:[[Playlist numberOfEntities] intValue] + 1];
    [[NSManagedObjectContext contextForCurrentThread] save];
    
    return playlist;
}

+ (void)replaceAndAddSong:(Song *)song {
    [Playlist truncateAll];
    [[NSManagedObjectContext contextForCurrentThread] save];
    
    MyPlaylist *playlist = [self addSongToQueue:song];
    [self setPlaylistToCurrent:playlist];
}

+ (Song *)currentSong {
    Song *song = nil;
    MyPlaylist *playlist = [Playlist findFirstWithPredicate:[NSPredicate predicateWithFormat:@"isCurrentSong = 1"]];
    if (playlist == nil) {
        playlist = [Playlist findFirstWithPredicate:[NSPredicate predicateWithFormat:@"SELF.queue_position == @min.queue_position"]];
    }
    
    if (playlist) {
        [MyPlaylist setPlaylistToCurrent:playlist];
        song = [Song findFirstByAttribute:@"song_id" withValue:playlist.song_id];
    }
    
    return song;
}

+ (MyPlaylist *)playlistItemForSong:(Song *)song {
    MyPlaylist *playlist = [Playlist findFirstWithPredicate:[NSPredicate predicateWithFormat:@"song_id = %i", song.song_id]];
    return playlist;
}

+ (Song *)songForPlaylistItem:(MyPlaylist *)playlist {
    return [Song findFirstByAttribute:@"song_id" withValue:playlist.song_id];
}

+ (void)currentSongDidFinish {
    MyPlaylist *playlist = [Playlist findFirstWithPredicate:[NSPredicate predicateWithFormat:@"isCurrentSong = 1"]];
    
    if (playlist) {
        MyPlaylist *newPlaylist = [Playlist findFirstWithPredicate:[NSPredicate predicateWithFormat:@"queue_position > %i", [playlist.queue_position intValue]]];
        if (newPlaylist) {
            [self setPlaylistToCurrent:newPlaylist];
        }
    }
}

+ (void)setPlaylistToCurrent:(MyPlaylist *)playlist {
    NSArray *playlists = [Playlist findAllWithPredicate:[NSPredicate predicateWithFormat:@"isCurrentSong = 1"]];
    for (MyPlaylist *p in playlists) {
        p.isCurrentSong = [NSNumber numberWithBool:NO];
    }
    playlist.isCurrentSong = [NSNumber numberWithBool:YES];
    [[NSManagedObjectContext contextForCurrentThread] save];
}

+ (NSArray *)allItemsSortedByQueuePosition {
    return [Playlist findAllSortedBy:@"queue_position" ascending:NO inContext:[NSManagedObjectContext contextForCurrentThread]];
}

@end
