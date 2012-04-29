//
//  db.h
//  LACMA2
//
//  Created by kampfgnu on 9/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <sqlite3.h>

@interface Db : NSObject

- (id)initWithName:(NSString *)databaseName;
- (void)buildDatabase;

@end
