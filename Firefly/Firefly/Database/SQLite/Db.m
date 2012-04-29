//
//  db.m
//  LACMA2
//
//  Created by kampfgnu on 9/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Db.h"

#import "ActiveRecordHelpers.h"
#import "NSManagedObject+ActiveRecord.h"
#import "NSManagedObjectContext+ActiveRecord.h"

#import "Folder.h"
#import "Song.h"

@interface Db ()

- (BOOL)openDatabase;
- (void)finalizeDatabase;
- (void)closeDatabase;

@property (nonatomic, strong) NSString *databaseName;
@property (nonatomic, strong) NSString *databaseFilepath;
@property (nonatomic, readwrite) sqlite3 *database;
@property (nonatomic, readwrite) const char *query;
@property (nonatomic, readwrite) sqlite3_stmt *compiledStatement;

@end


@implementation Db

$synthesize(databaseName);
$synthesize(databaseFilepath);
$synthesize(database);
$synthesize(query);
$synthesize(compiledStatement);

- (id)initWithName:(NSString *)databaseName {
	self.databaseName = databaseName;
	self.databaseFilepath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseName];
	
	//try to open db, else return
	if([self openDatabase] == NO) exit(1);
	return self;
}

- (BOOL)openDatabase {
	if (sqlite3_open([databaseFilepath_ UTF8String], &database_) == SQLITE_OK)
		return YES;
	else {
		NSLog(@"couldn't open database");
		return NO;
	}
}

-(void)finalizeDatabase {
	sqlite3_finalize(compiledStatement_);
}

- (void)closeDatabase {
	sqlite3_close(database_);
}

- (void)buildDatabase {
    
//    Folder *f1 = [Folder existingOrNewObjectWithAttribute:@"name" matchingValue:@"fuck2"];
//    Folder *f2 = [Folder existingOrNewObjectWithAttribute:@"name" matchingValue:@"muarg222"];
//    
//    [f2 setParent:f1];
//    
//    [[NSManagedObjectContext contextForCurrentThread] save];
//    
//    return;
    
    [Folder truncateAll];
    [Song truncateAll];
    
    NSString *_query = @"SELECT * FROM songs";
	query_ = [[NSString stringWithFormat:_query] cStringUsingEncoding:NSUTF8StringEncoding];
	
	if(sqlite3_prepare_v2(database_, query_, -1, &compiledStatement_, NULL) == SQLITE_OK) {
        BOOL finished = NO;
        while(sqlite3_step(compiledStatement_) == SQLITE_ROW && !finished) {
            int songId = sqlite3_column_int(compiledStatement_, 0);
            NSString *songPath = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 1)];
            NSString *songFilename = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 2)];
//            NSString *songFilename = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 2)];
//            NSString *songFilename = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 2)];
//            NSString *songFilename = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 2)];
//            NSString *songFilename = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 2)];
//            NSString *songFilename = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 2)];
//            NSString *songFilename = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 2)];
//            NSString *songFilename = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 2)];
            
            NSArray *folderPathSeparated = [songPath componentsSeparatedByString:@"/"];
            NSMutableArray *folders = [NSMutableArray arrayWithArray:folderPathSeparated];
            [folders removeObjectAtIndex:0];
            [folders removeObjectAtIndex:0];
            [folders removeObjectAtIndex:0];
            [folders removeLastObject];
            
            Folder *parentFolder;
            for (NSString *subpath in folders) {
                Folder *subFolder = [Folder existingOrNewObjectWithAttribute:@"name" matchingValue:subpath];
                [subFolder setParent:parentFolder];
                parentFolder = subFolder;
            }
            
            Song *song = [Song createEntity];
            song.title = songFilename;
            song.song_id = [NSNumber numberWithInt:songId];
            [song setFolder:parentFolder];

            
            //if (anId == 13) finished = YES;
        }
		[self finalizeDatabase];
	}
    
    [[NSManagedObjectContext contextForCurrentThread] save];
}

/*
-(id)getAreaById:(NSInteger)_daId {
	NSString *_query = [NSString stringWithFormat:@"SELECT * FROM area WHERE id=%i", _daId];
	query = [[NSString stringWithFormat:_query] cStringUsingEncoding:NSUTF8StringEncoding];
	Area *anArea;// = [[Area alloc] init];
	
	if(sqlite3_prepare_v2(db, query, -1, &compiledStatement, NULL) == SQLITE_OK) {
		int result = sqlite3_step(compiledStatement);
		if (result == SQLITE_ROW) {
			int anId = sqlite3_column_int(compiledStatement, 0);
			NSString *aName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
			//create object
			anArea = [[Area alloc] initWithId:anId name:aName];
		}
		[self finalizeDB];
	}
	//NSLog([NSString stringWithFormat:@"areacount: %i", areas.count]);
	return anArea;
}


-(id)getCabinets {
	NSMutableArray *cabinets = [[NSMutableArray alloc] init];
	NSString *_query = [NSString stringWithFormat:@"SELECT * FROM cabinet"];
	query = [[NSString stringWithFormat:_query] cStringUsingEncoding:NSUTF8StringEncoding];
	
	if(sqlite3_prepare_v2(db, query, -1, &compiledStatement, NULL) == SQLITE_OK) {
		while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
			//get values from row
			int anId = sqlite3_column_int(compiledStatement, 0);
			int anArea = sqlite3_column_int(compiledStatement, 1);
			NSString *aName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 2)];
			//create object
			Cabinet *aCabinet = [[Cabinet alloc] initWithId:anId area:anArea name:aName];
			
			//add to array and return it
			[cabinets addObject:aCabinet];
			[aCabinet release];
		}
		[self finalizeDB];
	}
	//NSLog([NSString stringWithFormat:@"areacount: %i", areas.count]);
	return cabinets;
}

-(id)getCabinetsByArea:(NSInteger) _area {
	NSMutableArray *cabinets = [[NSMutableArray alloc] init];
	NSString *_query = [NSString stringWithFormat:@"SELECT * FROM cabinet WHERE area=%i", _area];
	query = [[NSString stringWithFormat:_query] cStringUsingEncoding:NSUTF8StringEncoding];
	
	if(sqlite3_prepare_v2(db, query, -1, &compiledStatement, NULL) == SQLITE_OK) {
		while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
			//get values from row
			int anId = sqlite3_column_int(compiledStatement, 0);
			int anArea = sqlite3_column_int(compiledStatement, 1);
			NSString *aName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 2)];
			//create object
			Cabinet *aCabinet = [[Cabinet alloc] initWithId:anId area:anArea name:aName];
			
			//add to array and return it
			[cabinets addObject:aCabinet];
			[aCabinet release];
		}
		[self finalizeDB];
	}
	//NSLog([NSString stringWithFormat:@"areacount: %i", areas.count]);
	return cabinets;
}

-(id)getCabinetByAreaAndId:(NSInteger) _area daId:(NSInteger)_daId {
	NSString *_query = [NSString stringWithFormat:@"SELECT * FROM cabinet WHERE area=%i AND id=%i", _area, _daId];
	query = [[NSString stringWithFormat:_query] cStringUsingEncoding:NSUTF8StringEncoding];
	Cabinet *aCabinet;// = [[Cabinet alloc] init];
	
	if(sqlite3_prepare_v2(db, query, -1, &compiledStatement, NULL) == SQLITE_OK) {
		int result = sqlite3_step(compiledStatement);
		if (result == SQLITE_ROW) {
			int anId = sqlite3_column_int(compiledStatement, 0);
			int anArea = sqlite3_column_int(compiledStatement, 1);
			NSString *aName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 2)];
			//create object
			aCabinet = [[Cabinet alloc] initWithId:anId area:anArea name:aName];
		}
		[self finalizeDB];
	}
	//NSLog([NSString stringWithFormat:@"areacount: %i", areas.count]);
	return aCabinet;
}

-(id)getExhibitsByAreaAndCabinet:(NSInteger) _area cabinet:(NSInteger) _cabinet {
	NSMutableArray *exhibits = [[NSMutableArray alloc] init];
	NSString *_query = [NSString stringWithFormat:@"SELECT * FROM exhibit WHERE area=%i and cabinet=%i", _area, _cabinet];
	query = [[NSString stringWithFormat:_query] cStringUsingEncoding:NSUTF8StringEncoding];
	
	if(sqlite3_prepare_v2(db, query, -1, &compiledStatement, NULL) == SQLITE_OK) {
		while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
			//get values from row
			int anId = sqlite3_column_int(compiledStatement, 0);
			int anArea = sqlite3_column_int(compiledStatement, 1);
			int aCabinet = sqlite3_column_int(compiledStatement, 2);
			NSString *aName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 3)];
			NSString *aDescription = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 4)];
			NSString *aYear = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 5)];
			//create object
			Exhibit *anExhibit = [[Exhibit alloc] initWithId:anId area:anArea cabinet:aCabinet name:aName description:aDescription year:aYear];
			
			//add to array and return it
			[exhibits addObject:anExhibit];
			[anExhibit release];
		}
		[self finalizeDB];
	}
	//NSLog([NSString stringWithFormat:@"areacount: %i", areas.count]);
	return exhibits;
}

-(id)getExhibitById:(NSInteger)_daId {
	NSString *_query = [NSString stringWithFormat:@"SELECT * FROM exhibit WHERE id=%i", _daId];
	query = [[NSString stringWithFormat:_query] cStringUsingEncoding:NSUTF8StringEncoding];
	Exhibit *anExhibit;// = [[Exhibit alloc] init];
	
	if(sqlite3_prepare_v2(db, query, -1, &compiledStatement, NULL) == SQLITE_OK) {
		int result = sqlite3_step(compiledStatement);
		if (result == SQLITE_ROW) {
			//get values from row
			int anId = sqlite3_column_int(compiledStatement, 0);
			int anArea = sqlite3_column_int(compiledStatement, 1);
			int aCabinet = sqlite3_column_int(compiledStatement, 2);
			NSString *aName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 3)];
			NSString *aDescription = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 4)];
			NSString *aYear = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 5)];
			//create object
			anExhibit = [[Exhibit alloc] initWithId:anId area:anArea cabinet:aCabinet name:aName description:aDescription year:aYear];
		}
		[self finalizeDB];
	}
	//NSLog(@"area: %i, cab: %i", [anExhibit getArea], [anExhibit getCabinet]);
	return anExhibit;
}

-(id)getAreas {
	NSMutableArray *areas = [[NSMutableArray alloc] init];
	NSString *_query = [NSString stringWithFormat:@"SELECT * FROM area"];
	query = [[NSString stringWithFormat:_query] cStringUsingEncoding:NSUTF8StringEncoding];
	
	if(sqlite3_prepare_v2(db, query, -1, &compiledStatement, NULL) == SQLITE_OK) {
		while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
			//get values from row
			int anId = sqlite3_column_int(compiledStatement, 0);
			NSString *aName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
			//create object
			Area *anArea = [[Area alloc] initWithId:anId name:aName];
			
			//add to array and return it
			[areas addObject:anArea];
			[anArea release];
		}
		[self finalizeDB];
	}
	//NSLog([NSString stringWithFormat:@"areacount: %i", areas.count]);
	return areas;
}
*/
@end
