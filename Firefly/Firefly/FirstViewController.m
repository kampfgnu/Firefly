//
//  FirstViewController.m
//  Firefly
//
//  Created by kampfgnu on 4/27/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "FirstViewController.h"

#import "AFNetworking.h"

#import <MediaPlayer/MediaPlayer.h>

@interface FirstViewController ()

@end

@implementation FirstViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"First", @"First");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}
							
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    return;
    
    
//    NSURL *baseURL = [NSURL URLWithString:@"http://debian:3689"];
    NSURL *baseURL = [NSURL URLWithString:@"http://kampfgnu.dyndns.tv:3689"];
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:baseURL];
    [client setAuthorizationHeaderWithUsername:@"" password:@"mt-daapd_Mongo0815"];
    client.parameterEncoding = AFJSONParameterEncoding;
//    client.parameterEncoding = AFFormURLParameterEncoding;

//    NSDictionary *loginParams = [NSDictionary dictionaryWithObject:@"mt-daapd_Mongo0815" forKey:@"password"];
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
    
    
}

- (void)viewDidAppear:(BOOL)animated {
//    MPMoviePlayerViewController *vc = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:@"http://kampfgnu.dyndns.tv:3689/databases/1/items/1000.mp3"]];
//    [self presentMoviePlayerViewControllerAnimated:vc];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
