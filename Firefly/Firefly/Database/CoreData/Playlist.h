//
//  Playlist.h
//  Firefly
//
//  Created by kampfgnu on 5/4/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PlaylistItem;

@interface Playlist : NSManagedObject

@property (nonatomic, retain) NSNumber * item_id;
@property (nonatomic, retain) PlaylistItem *currentPlaylistItem;

@end
