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
#import "Folder.h"

@interface MyPlaylist ()

+ (void)addFolderRecursively:(Folder *)folder;

@end


@implementation MyPlaylist

+ (void)addFolderToQueue:(Folder *)folder recursively:(BOOL)recursively {
    if (!recursively) {
        NSArray *songs = [Song findAllWithPredicate:[NSPredicate predicateWithFormat:@"folder = %@", folder] sortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"track" ascending:YES]]];
        for (Song *song in songs) {
            [self addSongToQueue:song];
        }
    }
    else {
        [self addFolderRecursively:folder];
    }
    
}

+ (void)addFolderRecursively:(Folder *)folder {
    NSArray *childrenToVisit = [Folder findAllWithPredicate:[NSPredicate predicateWithFormat:@"parent = %@", folder] sortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    
    int i, count = childrenToVisit.count;
        
    NSArray *songs = [Song findAllWithPredicate:[NSPredicate predicateWithFormat:@"folder = %@", folder] sortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"track" ascending:YES]]];
    for (Song *song in songs) {
        [self addSongToQueue:song];
    }
        
    // if there are no children, then recursion ends:
    for (i = 0; i < count; i++) {
        // make recursive call:
        [self addFolderRecursively:[childrenToVisit objectAtIndex:i]];
    }
}

+ (MyPlaylist *)addSongToQueue:(Song *)song {
    Playlist *maxPlaylist = [Playlist findFirstWithPredicate:[NSPredicate predicateWithFormat:@"SELF.queue_position == @max.queue_position"]];
    
    MyPlaylist *playlist = [Playlist createEntity];
    playlist.song_id = song.song_id;
    playlist.isCurrentSong = [NSNumber numberWithBool:NO];
    playlist.progress = [NSNumber numberWithFloat:0.f];
        
    playlist.queue_position = [NSNumber numberWithInt:(maxPlaylist ? [maxPlaylist.queue_position intValue] : 0) + 1];
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
    return [Playlist findAllSortedBy:@"queue_position" ascending:YES inContext:[NSManagedObjectContext contextForCurrentThread]];
}

@end
