//
//  Folder.h
//  Firefly
//
//  Created by kampfgnu on 5/4/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Folder;

@interface Folder : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * layer;
@property (nonatomic, retain) Folder *parent;

@end
