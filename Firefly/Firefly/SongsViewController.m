//
//  SongsViewController.m
//  Firefly
//
//  Created by kampfgnu on 2/10/13.
//  Copyright (c) 2013 NOUS. All rights reserved.
//

#import "SongsViewController.h"
#import "Db.h"

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
            NSLog(@"artists: %@", _objects);
        }
        else if (_listType == ListTypeAlbums) {
            _objects = [[Db sharedDb] albumsOfArtist:queryString];
            NSLog(@"albums: %@", _objects);
        }
        else if (_listType == ListTypeSongs) {
            _objects = [[Db sharedDb] songsOfAlbum:queryString];
            NSLog(@"songs: %@", _objects);
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [_objects objectAtIndex:indexPath.row];
    
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
    }
    else if (_listType == ListTypeAlbums) {
        vc = [[SongsViewController alloc] initWithStyle:UITableViewStylePlain listType:ListTypeSongs queryString:title];
    }
    else if (_listType == ListTypeSongs) {

    }

    [self.navigationController pushViewController:vc animated:YES];
}

@end
