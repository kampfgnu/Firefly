//
//  Playlist+Extensions.m
//  Firefly
//
//  Created by kampfgnu on 5/4/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "Playlist+Extensions.h"
#import "NSManagedObject+ActiveRecord.h"
#import "NSManagedObjectContext+ActiveRecord.h"
#import "Song.h"
#import "Folder.h"
#import "PlaylistItem.h"

@implementation Playlist (Extensions)

+ (Playlist *)currentPlaylist {
    Playlist *currentPlaylist = [Playlist findFirstByAttribute:@"item_id" withValue:@"0"];
    if (!currentPlaylist) {
        currentPlaylist = [Playlist createEntity];
        currentPlaylist.item_id = [NSNumber numberWithInt:0];
        
        [[NSManagedObjectContext contextForCurrentThread] save];
    }
    
    return currentPlaylist;
}

- (void)addSongToList:(Song *)song replace:(BOOL)replace {
    if (replace) {
        [PlaylistItem truncateAll];
        [[NSManagedObjectContext contextForCurrentThread] save];
    }
    
    PlaylistItem *lastItemInPlaylist = [PlaylistItem findFirstWithPredicate:[NSPredicate predicateWithFormat:@"SELF.queue_position == @max.queue_position AND playlist = %@", self]];
    
    PlaylistItem *playlistItem = [PlaylistItem createEntity];
    playlistItem.song = song;
    playlistItem.progress = [NSNumber numberWithFloat:0.f];
    playlistItem.playlist = self;
    playlistItem.queue_position = [NSNumber numberWithInt:(lastItemInPlaylist ? [lastItemInPlaylist.queue_position intValue] : 0) + 1];
    [[NSManagedObjectContext contextForCurrentThread] save];
    
    if (replace) {
        self.currentPlaylistItem = playlistItem;
        [[NSManagedObjectContext contextForCurrentThread] save];
    }
    
}

- (void)addFolderToList:(Folder *)folder recursively:(BOOL)recursively replace:(BOOL)replace {
    if (replace) {
        [PlaylistItem truncateAll];
        [[NSManagedObjectContext contextForCurrentThread] save];
    }
    
    if (!recursively) {
        NSArray *songs = [Song findAllWithPredicate:[NSPredicate predicateWithFormat:@"folder = %@", folder] sortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"track" ascending:YES]]];
        for (Song *song in songs) {
            [self addSongToList:song replace:NO];
        }
    }
    else {
        [self addFolderRecursively:folder];
    }
    
}

- (void)addFolderRecursively:(Folder *)folder {
    NSArray *childrenToVisit = [Folder findAllWithPredicate:[NSPredicate predicateWithFormat:@"parent = %@", folder] sortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    
    int i, count = childrenToVisit.count;
    
    NSArray *songs = [Song findAllWithPredicate:[NSPredicate predicateWithFormat:@"folder = %@", folder] sortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"track" ascending:YES]]];
    for (Song *song in songs) {
        [self addSongToList:song replace:NO];
    }
    
    // if there are no children, then recursion ends:
    for (i = 0; i < count; i++) {
        // make recursive call:
        [self addFolderRecursively:[childrenToVisit objectAtIndex:i]];
    }
}

- (NSArray *)allPlaylistItemsSortedByQueuePosition {
    return [PlaylistItem findAllSortedBy:@"queue_position" ascending:YES inContext:[NSManagedObjectContext contextForCurrentThread]];
}

- (void)skipToPlaylistItem:(BOOL)toNext {
    if (self.currentPlaylistItem != nil) {
        PlaylistItem *nextPlaylistItem = nil;
        
        if (toNext) {
            nextPlaylistItem = [PlaylistItem findFirstWithPredicate:[NSPredicate predicateWithFormat:@"SELF.queue_position > %i AND playlist = %@", [self.currentPlaylistItem.queue_position intValue], self]];
        }
        else {
            nextPlaylistItem = [PlaylistItem findFirstWithPredicate:[NSPredicate predicateWithFormat:@"SELF.queue_position < %i AND playlist = %@", [self.currentPlaylistItem.queue_position intValue], self]];
        }
        
        self.currentPlaylistItem = nextPlaylistItem;
        [[NSManagedObjectContext contextForCurrentThread] save];
    }
}

@end
