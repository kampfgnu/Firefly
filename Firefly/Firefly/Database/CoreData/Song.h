//
//  Song.h
//  Firefly
//
//  Created by kampfgnu on 4/28/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Folder;

@interface Song : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * song_id;
@property (nonatomic, retain) Folder *folder;

@end
