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
#import "UIView+Sizes.h"

@interface SettingsViewController ()

@property (nonatomic, strong) NSMutableArray *actions;

@end


@implementation SettingsViewController

$synthesize(actions);

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.actions = [NSMutableArray array];
        [self.actions addObject:@"Download songs3.db"];
//        [self.actions addObject:@"Reload database"];
//        [self.actions addObject:@"Download coredatasqlite"];
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
        progressView.left += 80;
        progressView.width = 100;
        [cell.detailTextLabel addSubview:progressView];
    }
    
    cell.textLabel.text = [self.actions objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UIProgressView *progressView = (UIProgressView *)[cell.detailTextLabel viewWithTag:indexPath.row + 666];
    
//    if (indexPath.row == 0) {
//        Db *db = [[Db alloc] initWithName:kMTDAAPDServerDatabaseName];
//        [db buildDatabase:^(float progress) {
////            NSLog(@"progress: %f", progress);
//            progressView.progress = progress;
//            if (progress == 1.0f) progressView.progress = 0.0f;
//        }];
//    }
    if (indexPath.row == 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        NSURL *baseURL = [NSURL URLWithString:[kMTDAAPDServerDatabaseUrlPath stringByAppendingPathComponent:kMTDAAPDServerDatabaseName]];
        NSURLRequest *request = [NSURLRequest requestWithURL:baseURL];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id response) {
            NSLog(@"success");
            if (response) {
                [NSFileManager writeDataToNoBackupDirectory:response filename:kMTDAAPDServerDatabaseName];
            }
            cell.detailTextLabel.text = @"done";
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"%@", error);                                    
        }];
        
        [operation setDownloadProgressBlock:^(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
            float progress = (float)totalBytesRead/(float)totalBytesExpectedToRead;
            progressView.progress = progress;
            if (progress == 1.0f) progressView.progress = 0.0f;
        }];

        [operation start];
    }
//    else if (indexPath.row == 2) {
//        NSURL *baseURL = [NSURL URLWithString:[kMTDAAPDServerDatabaseUrlPath stringByAppendingPathComponent:kMTDAAPDiPhoneDatabaseName]];
//        NSURLRequest *request = [NSURLRequest requestWithURL:baseURL];
//        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
//        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id response) {
//            NSLog(@"success");
//            if (response) {
//                [NSFileManager writeDataToDocumentsDirectory:response filename:kMTDAAPDiPhoneDatabaseName];
//            }
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            NSLog(@"%@", error);                                    
//        }];
//        
//        [operation setDownloadProgressBlock:^(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
//            float progress = (float)totalBytesRead/(float)totalBytesExpectedToRead;
//            progressView.progress = progress;
//            if (progress == 1.0f) progressView.progress = 0.0f;
//        }];
//        
//        [operation start];
//    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
