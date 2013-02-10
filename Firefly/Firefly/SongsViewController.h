//
//  SongsViewController.h
//  Firefly
//
//  Created by kampfgnu on 2/10/13.
//  Copyright (c) 2013 NOUS. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ListTypeArtists,
    ListTypeAlbums,
    ListTypeSongs
} ListType;

@interface SongsViewController : UITableViewController

- (id)initWithStyle:(UITableViewStyle)style listType:(ListType)listType queryString:(NSString *)queryString;

@end
