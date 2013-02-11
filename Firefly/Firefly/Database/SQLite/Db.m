//
//  db.m
//  LACMA2
//
//  Created by kampfgnu on 9/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Db.h"

#import "NSFileManager+KGiOSHelper.h"

#import "ActiveRecordHelpers.h"
#import "NSManagedObject+ActiveRecord.h"
#import "NSManagedObjectContext+ActiveRecord.h"

#import "Folder.h"
#import "Song.h"

static dispatch_queue_t coredata_processing_queue;
static dispatch_queue_t coredata_processing_queue_method() {
    if (coredata_processing_queue == NULL) {
        coredata_processing_queue = dispatch_queue_create("coredata.processing", 0);
    }
    
    return coredata_processing_queue;
}

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

+ (Db *)sharedDb {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init {
	self.databaseName = kMTDAAPDServerDatabaseName;
	self.databaseFilepath = [[NSFileManager documentsNoBackupDirectoryPath] stringByAppendingPathComponent:self.databaseName];
	
	//try to open db, else return
	if([self openDatabase] == NO) exit(1);
	return self;
}

- (id)initWithName:(NSString *)databaseName {
	self.databaseName = databaseName;
	self.databaseFilepath = [[NSFileManager documentsNoBackupDirectoryPath] stringByAppendingPathComponent:self.databaseName];
	
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

- (NSMutableArray *)songsOfAlbum:(NSString *)album {
     NSString *_query = [NSString stringWithFormat:@"select * from songs where album=\"%@\" order by track ASC", album];
    query_ = [_query cStringUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableArray *result = [NSMutableArray array];
    if(sqlite3_prepare_v2(database_, query_, -1, &compiledStatement_, NULL) == SQLITE_OK) {
        while(sqlite3_step(compiledStatement_) == SQLITE_ROW) {
            int songId = sqlite3_column_int(compiledStatement_, 0); //NSLog(@"song item: %i", songId);
            
//            NSString *songPath = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 1)];
            NSString *songFilename = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 2)];
            NSString *songTitle = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 3)];
            NSString *songArtist = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 4)];
            NSString *songAlbum = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 5)];
            NSString *songGenre = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 6)];
            int songLength = sqlite3_column_int(compiledStatement_, 16);
            int songFileSize = sqlite3_column_int(compiledStatement_, 17);
            //                NSLog(@"kength: %i", songLength);
            int songYear = sqlite3_column_int(compiledStatement_, 18);
            int songTrack = sqlite3_column_int(compiledStatement_, 19);
            
            
            Song *song = [Song createEntity];
            song.song_id = [NSNumber numberWithInt:songId];
            song.filename = songFilename;
            song.title = songTitle;
            song.artist = songArtist;
            song.album = songAlbum;
            song.genre = songGenre;
            song.song_length = [NSNumber numberWithInt:songLength];
            song.file_size = [NSNumber numberWithInt:songFileSize];
            song.year = [NSNumber numberWithInt:songYear];
            song.track = [NSNumber numberWithInt:songTrack];

            
            
            
            
            
            
            
            
            //            NSString *songArtist = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 4)];
            //            NSLog(@"artist: %@", songArtist);
//            NSString *songAlbum = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 5)];
//            NSLog(@"artist: %@", songAlbum);
//            NSString *songTitle = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 3)];
//            int songTrack = sqlite3_column_int(compiledStatement_, 19);
            
            [result addObject:song];
            //            NSString *songPath = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 1)];
        }
    }
    
    return result;
}

- (NSMutableArray *)albumsOfArtist:(NSString *)artist {
    NSString *_query = [NSString stringWithFormat:@"select album from songs where artist=\"%@\" group by album", artist];
    query_ = [_query cStringUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableArray *result = [NSMutableArray array];
    if(sqlite3_prepare_v2(database_, query_, -1, &compiledStatement_, NULL) == SQLITE_OK) {
        while(sqlite3_step(compiledStatement_) == SQLITE_ROW) {
            //            int songId = sqlite3_column_int(compiledStatement_, 0); //NSLog(@"song item: %i", songId);
            
            NSString *songAlbum = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 0)];
            [result addObject:songAlbum];
            //            NSLog(@"artist: %@", songArtist);
            //            NSString *songAlbum = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 5)];
            //            NSLog(@"artist: %@", songAlbum);
            //            NSString *songPath = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 1)];
        }
    }
    
    return result;
}

- (NSMutableArray *)artists {
    NSString *_query = @"select artist from songs group by artist;";
    query_ = [_query cStringUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableArray *result = [NSMutableArray array];
    if(sqlite3_prepare_v2(database_, query_, -1, &compiledStatement_, NULL) == SQLITE_OK) {
        while(sqlite3_step(compiledStatement_) == SQLITE_ROW) {
//            int songId = sqlite3_column_int(compiledStatement_, 0); //NSLog(@"song item: %i", songId);
            
            NSString *songArtist = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 0)];
            [result addObject:songArtist];
//            NSLog(@"artist: %@", songArtist);
//            NSString *songAlbum = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 5)];
//            NSLog(@"artist: %@", songAlbum);
//            NSString *songPath = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 1)];
        }
    }
    
    return result;
}

- (void)buildDatabase:(void(^)(float))callback {
    dispatch_async(coredata_processing_queue_method(), ^(void) {
        [Folder truncateAll];
        [Song truncateAll];
        
        //get number of songs
        NSString *countQuery = @"select count(*) from songs;";
        query_ = [[NSString stringWithFormat:countQuery] cStringUsingEncoding:NSUTF8StringEncoding];

        int numRows = 0;
        if(sqlite3_prepare_v2(database_, query_, -1, &compiledStatement_, NULL) == SQLITE_OK) {
            int result = sqlite3_step(compiledStatement_);
                if (result == SQLITE_ROW) {
                    numRows = sqlite3_column_int(compiledStatement_, 0);
//                    NSLog(@"numrows: %i", numRows);
                }
        }
        sqlite3_finalize(compiledStatement_);
        
        
        //build database
        NSString *_query = @"select * from songs;";
        query_ = [[NSString stringWithFormat:_query] cStringUsingEncoding:NSUTF8StringEncoding];
        
        if(sqlite3_prepare_v2(database_, query_, -1, &compiledStatement_, NULL) == SQLITE_OK) {
            BOOL finished = NO;

            while(sqlite3_step(compiledStatement_) == SQLITE_ROW && !finished) {
                int songId = sqlite3_column_int(compiledStatement_, 0); //NSLog(@"song item: %i", songId);
                
                if (callback) {
                    dispatch_sync(dispatch_get_main_queue(), ^{callback((float)songId/(float)numRows);});
                }
                
                NSString *songPath = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 1)];
                NSString *songFilename = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 2)];
                NSString *songTitle = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 3)];
                NSString *songArtist = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 4)];
                NSString *songAlbum = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 5)];
                NSString *songGenre = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement_, 6)];
                int songLength = sqlite3_column_int(compiledStatement_, 16);
                int songFileSize = sqlite3_column_int(compiledStatement_, 17);
//                NSLog(@"kength: %i", songLength);
                int songYear = sqlite3_column_int(compiledStatement_, 18);
                int songTrack = sqlite3_column_int(compiledStatement_, 19);
                
                NSArray *folderPathSeparated = [songPath componentsSeparatedByString:@"/"];
                NSMutableArray *folders = [NSMutableArray arrayWithArray:folderPathSeparated];
                [folders removeObjectAtIndex:0];
                [folders removeObjectAtIndex:0];
                [folders removeObjectAtIndex:0];
                [folders removeLastObject];
                
                int layer = 0;
                Folder *parentFolder;
                for (NSString *subpath in folders) {
                    Folder *subFolder = [Folder existingOrNewObjectWithPredicate:[NSPredicate predicateWithFormat:@"name = %@ and layer = %i", subpath, layer]];
                    subFolder.name = subpath;
                    subFolder.layer = [NSNumber numberWithInt:layer];
                    [subFolder setParent:parentFolder];
                    parentFolder = subFolder;
                    layer++;
                }
                
                Song *song = [Song createEntity];
                song.song_id = [NSNumber numberWithInt:songId];
                song.filename = songFilename;
                song.title = songTitle;
                song.artist = songArtist;
                song.album = songAlbum;
                song.genre = songGenre;
                song.song_length = [NSNumber numberWithInt:songLength];
                song.file_size = [NSNumber numberWithInt:songFileSize];
                song.year = [NSNumber numberWithInt:songYear];
                song.track = [NSNumber numberWithInt:songTrack];
                [song setFolder:parentFolder];
                
                
                //if (anId == 13) finished = YES;
            }
            [self finalizeDatabase];
        }
        
        [[NSManagedObjectContext contextForCurrentThread] save];
    });
    
    
}

@end
