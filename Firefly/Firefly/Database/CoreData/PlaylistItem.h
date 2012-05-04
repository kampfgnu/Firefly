//
//  PlaylistItem.h
//  Firefly
//
//  Created by kampfgnu on 5/4/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Playlist, Song;

@interface PlaylistItem : NSManagedObject

@property (nonatomic, retain) NSNumber * progress;
@property (nonatomic, retain) NSNumber * queue_position;
@property (nonatomic, retain) Playlist *playlist;
@property (nonatomic, retain) Song *song;

@end
