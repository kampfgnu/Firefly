//
//  FirstViewController.h
//  Firefly
//
//  Created by kampfgnu on 4/27/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

@class Folder;
@class PlayerViewController;
@class StreamerViewController;

@interface FileBrowserViewController : UITableViewController <UIActionSheetDelegate>

@property (nonatomic, strong) Folder *folder;
@property (nonatomic, unsafe_unretained) PlayerViewController *playerViewController;
@property (nonatomic, unsafe_unretained) StreamerViewController *streamerViewController;

@end
