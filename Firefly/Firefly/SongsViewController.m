//
//  SongsViewController.m
//  Firefly
//
//  Created by kampfgnu on 2/10/13.
//  Copyright (c) 2013 NOUS. All rights reserved.
//

#import "SongsViewController.h"
#import "Db.h"

#import "KGTimeConverter.h"
#import "Song.h"
#import "Playlist.h"
#import "StreamerViewController.h"
#import "Playlist+Extensions.h"
#import "NSManagedObject+ActiveRecord.h"
#import "NSManagedObjectContext+ActiveRecord.h"

@interface SongsViewController ()

@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, readwrite) ListType listType;

@end

@implementation SongsViewController

- (id)initWithStyle:(UITableViewStyle)style listType:(ListType)listType queryString:(NSString *)queryString {
    self = [super initWithStyle:style];
    if (self) {
        _listType = listType;
        
        if (_listType == ListTypeArtists) {
            _objects = [[Db sharedDb] artists];
            self.title = @"Artists";
//            NSLog(@"artists: %@", _objects);
        }
        else if (_listType == ListTypeAlbums) {
            _objects = [[Db sharedDb] albumsOfArtist:queryString];
            self.title = queryString;
//            NSLog(@"albums: %@", _objects);
        }
        else if (_listType == ListTypeSongs) {
            _objects = [[Db sharedDb] songsOfAlbum:queryString];
            self.title = queryString;
//            NSLog(@"songs: %@", _objects);
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_listType == ListTypeAlbums || _listType == ListTypeArtists) {
        return 44.f;
    }
    else {
        return 144.f;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:13];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.numberOfLines = 0;
    }
    
    if (_listType == ListTypeAlbums || _listType == ListTypeArtists) {
        cell.textLabel.text = [_objects objectAtIndex:indexPath.row];
    }
    else {
        Song *song = [_objects objectAtIndex:indexPath.row];
        cell.textLabel.text = song.title;
        
        KGTimeConverter *timeConverter = [KGTimeConverter timeConverterWithNumber:song.song_length];
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Track: %i\nArtist: %@\nAlbum: %@\nGenre: %@\nFilename: %@\nDuration: %@", [song.track intValue], song.artist, song.album, song.genre, song.filename, timeConverter.timeString];
    }
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SongsViewController *vc;
    
    NSString *title = [_objects objectAtIndex:indexPath.row];
    
    if (_listType == ListTypeArtists) {
        vc = [[SongsViewController alloc] initWithStyle:UITableViewStylePlain listType:ListTypeAlbums queryString:title];
        
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (_listType == ListTypeAlbums) {
        vc = [[SongsViewController alloc] initWithStyle:UITableViewStylePlain listType:ListTypeSongs queryString:title];
        
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (_listType == ListTypeSongs) {
        Song *song = [_objects objectAtIndex:indexPath.row];
        Playlist *currentPlaylist = [Playlist currentPlaylist];
        [currentPlaylist addSongToList:song replace:NO];
        [_streamerViewController start];
    }
}

@end
