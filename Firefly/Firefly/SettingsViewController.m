//
//  SettingsViewControllerViewController.m
//  Firefly
//
//  Created by kampfgnu on 4/28/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "SettingsViewController.h"

#import "Db.h"

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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [self.actions objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        Db *db = [[Db alloc] initWithName:@"songs3.db"];
        [db buildDatabase];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
