//
//  Playlist.h
//  Firefly
//
//  Created by kampfgnu on 5/2/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Playlist : NSManagedObject

@property (nonatomic, retain) NSNumber * song_id;
@property (nonatomic, retain) NSNumber * isCurrentSong;
@property (nonatomic, retain) NSNumber * progress;
@property (nonatomic, retain) NSNumber * queue_position;

@end
