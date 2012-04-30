//
//  Song.h
//  Firefly
//
//  Created by kampfgnu on 4/30/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Folder;

@interface Song : NSManagedObject

@property (nonatomic, retain) NSNumber * song_id;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSString * album;
@property (nonatomic, retain) NSString * genre;
@property (nonatomic, retain) NSNumber * song_length;
@property (nonatomic, retain) NSNumber * track;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) Folder *folder;

@end
