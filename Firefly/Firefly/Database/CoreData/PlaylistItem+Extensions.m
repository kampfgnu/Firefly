//
//  PlaylistItem+Extensions.m
//  Firefly
//
//  Created by kampfgnu on 5/4/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "PlaylistItem+Extensions.h"
#import "NSManagedObject+ActiveRecord.h"
#import "NSManagedObjectContext+ActiveRecord.h"

@implementation PlaylistItem (Extensions)

- (void)updateProgress:(float)progress {
    self.progress = [NSNumber numberWithFloat:progress];
    
    [[NSManagedObjectContext contextForCurrentThread] save];
}

@end
