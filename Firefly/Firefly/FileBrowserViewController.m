//
//  FirstViewController.m
//  Firefly
//
//  Created by kampfgnu on 4/27/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "FileBrowserViewController.h"

#import "PlayerViewController.h"
#import "StreamerViewController.h"
#import "Folder.h"
#import "Song.h"
#import "MyPlaylist.h"
#import "NSManagedObject+ActiveRecord.h"
#import "NSManagedObjectContext+ActiveRecord.h"
#import "UIView+Sizes.h"

@interface FileBrowserViewController ()

- (void)setTitleHeader;
- (void)reloadEntities;
- (void)longPress:(UILongPressGestureRecognizer *)gesture;
- (void)defaultActionForIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic, strong) NSArray *subfolders;
@property (nonatomic, strong) NSArray *songs;

@end

@implementation FileBrowserViewController

$synthesize(folder);
$synthesize(subfolders);
$synthesize(songs);
$synthesize(playerViewController);
$synthesize(streamerViewController);

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*
    NSURL *baseURL = [NSURL URLWithString:kBaseUrl];
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:baseURL];
    [client setAuthorizationHeaderWithUsername:@"" password:@"mt-daapd_Mongo0815"];
    client.parameterEncoding = AFJSONParameterEncoding;

    NSMutableDictionary *outputParams = [NSMutableDictionary dictionary];
//    [outputParams setObject:@"1" forKey:@"session-id"];
//    [outputParams setObject:@"genre" forKey:@"type"];
    [outputParams setObject:@"dmap.itemid" forKey:@"meta"];
    [outputParams setObject:@"xml" forKey:@"output"];
    [client getPath:@"/databases/1/items"
//    [client getPath:@"/server-info"
         parameters:outputParams
            success:^(AFHTTPRequestOperation *operation, id response) {
                NSString *text = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
                NSLog(@"Response: %@", text);
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error");
                NSLog(@"%@", error);                                    
            }];
    */    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self reloadEntities];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark - custom getter/setter
////////////////////////////////////////////////////////////////////////

- (void)setFolder:(Folder *)folder {
    folder_ = folder;
    
    [self reloadEntities];
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark - private methods
////////////////////////////////////////////////////////////////////////

- (void)setTitleHeader {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)];
    titleLabel.numberOfLines = 3;
    titleLabel.font = [UIFont boldSystemFontOfSize:12];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textAlignment = UITextAlignmentCenter;
    
    NSString *title = @"";
    
    Folder *currentFolder = self.folder;
    while (currentFolder != nil) {
        if (currentFolder.parent == nil) break;
        title = [currentFolder.name stringByAppendingFormat:@"\n%@", title];
        currentFolder = currentFolder.parent;
    }
    
    titleLabel.text = title;
    
    self.title = self.folder.name;
    self.navigationItem.titleView = titleLabel;
}

- (void)reloadEntities {
    if (self.folder == nil) folder_ = [Folder findFirstWithPredicate:[NSPredicate predicateWithFormat:@"parent = null"]];
    
    self.subfolders = [Folder findAllWithPredicate:[NSPredicate predicateWithFormat:@"parent = %@", folder_] sortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    
    
    self.songs = [Song findAllWithPredicate:[NSPredicate predicateWithFormat:@"folder = %@", folder_] sortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"track" ascending:YES]]];
    
    [self.tableView reloadData];
    
    [self setTitleHeader];
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDataSource
////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.subfolders.count : self.songs.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? (self.subfolders.count == 0 ? nil : @"Folders") : (self.songs.count == 0 ? nil : @"Songs");
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 40;
    }
    else return 140;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"EmptyCell";

    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:13];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
		[cell addGestureRecognizer:longPressGesture];
    }
    
    if (indexPath.section == 0) {
        Folder *folder = [self.subfolders objectAtIndex:indexPath.row];
        cell.textLabel.text = folder.name;
    }
    else {
        Song *song = [self.songs objectAtIndex:indexPath.row];
        cell.textLabel.text = song.title;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Track: %i\nArtist: %@\nAlbum: %@\nGenre: %@\nFilename: %@\nLength: %f", [song.track intValue], song.artist, song.album, song.genre, song.filename, [song.song_length intValue]/60000.f];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        FileBrowserViewController *vc = [[FileBrowserViewController alloc] initWithStyle:UITableViewStylePlain];
        vc.folder = [self.subfolders objectAtIndex:indexPath.row];
        vc.playerViewController = self.playerViewController;
        vc.streamerViewController = self.streamerViewController;
        
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        [self defaultActionForIndexPath:indexPath];
    }
}

- (void)longPress:(UILongPressGestureRecognizer *)gesture {
	// only when gesture was recognized, not when ended
	if (gesture.state == UIGestureRecognizerStateBegan) {
		// get affected cell
		UITableViewCell *cell = (UITableViewCell *)[gesture view];
        
		// get indexPath of cell
		NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Action for selection" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add to playlist", @"Play now", nil];
        actionSheet.tag = indexPath.row;
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
	}
}

- (void)defaultActionForIndexPath:(NSIndexPath *)indexPath {
    Song *song = [self.songs objectAtIndex:indexPath.row];
    [MyPlaylist replaceAndAddSong:song];
    [self.streamerViewController start];
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark - UIActionSheetDelegate
////////////////////////////////////////////////////////////////////////

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex == buttonIndex) return;
    else {
        if (self.streamerViewController) {
            Song *song = [self.songs objectAtIndex:actionSheet.tag];
            if (buttonIndex == 0) {
                [MyPlaylist addSongToQueue:song];
                [self.streamerViewController updateUI];
            }
            else if (buttonIndex == 1) {
                [MyPlaylist replaceAndAddSong:song];
                [self.streamerViewController start];
            }
        }
    }
}

@end
