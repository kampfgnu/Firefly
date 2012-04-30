//
//  SettingsViewControllerViewController.m
//  Firefly
//
//  Created by kampfgnu on 4/28/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "SettingsViewController.h"

#import "Db.h"
#import "AFNetworking.h"
#import "NSFileManager+KGiOSHelper.h"
#import <dispatch/dispatch.h>

@interface SettingsViewController ()

@property (nonatomic, strong) NSMutableArray *actions;

@end


@implementation SettingsViewController

$synthesize(actions);

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.actions = [NSMutableArray array];
        [self.actions addObject:@"Reload database"];
        [self.actions addObject:@"Download songs3.db"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.actions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.detailTextLabel.text = @"                                                     ";
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        progressView.tag = indexPath.row + 666;
        [cell.detailTextLabel addSubview:progressView];
    }
    
    cell.textLabel.text = [self.actions objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UIProgressView *progressView = (UIProgressView *)[cell.detailTextLabel viewWithTag:indexPath.row + 666];
    
    if (indexPath.row == 0) {
        Db *db = [[Db alloc] initWithName:kMTDAAPDServerDatabaseName];
        [db buildDatabase:^(float progress) {
//            NSLog(@"progress: %f", progress);
            progressView.progress = progress;
            if (progress == 1.0f) progressView.progress = 0.0f;
        }];
    }
    else if (indexPath.row == 1) {
        
        NSURL *baseURL = [NSURL URLWithString:[kMTDAAPDServerDatabaseUrlPath stringByAppendingPathComponent:kMTDAAPDServerDatabaseName]];
        NSURLRequest *request = [NSURLRequest requestWithURL:baseURL];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id response) {
            NSLog(@"success");
            if (response) {
                [NSFileManager writeDataToNoBackupDirectory:response filename:kMTDAAPDServerDatabaseName];
            }
            //NSLog(@"Success: %i", [response writeToFile:@"downloadedSongsbla.db" atomically:YES encoding:NSUTF8StringEncoding error:nil]);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"%@", error);                                    
        }];
        
        [operation setDownloadProgressBlock:^(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
//            NSLog(@"Get %d of %d bytes", totalBytesRead, totalBytesExpectedToRead);
            //float totalBytesInMB = totalBytesRead / 1024.0f / 1000.0f;
            //NSString *result = [NSString stringWithFormat:@"%0.2f MB", totalBytesInMB];
            float progress = (float)totalBytesRead/(float)totalBytesExpectedToRead;
//            NSLog(@"progress: %f", progress);
            progressView.progress = progress;
            if (progress == 1.0f) progressView.progress = 0.0f;
            
//            void (^progressUpdate)(void) = ^ {
//                progressView.progress = progress;
//                NSLog(@"progress: %f", progress);
//            };
//            
//            dispatch_sync(dispatch_get_main_queue(), progressUpdate);
            
            
        }];

        [operation start];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
