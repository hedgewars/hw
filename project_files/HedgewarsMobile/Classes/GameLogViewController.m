/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2015 Anton Malmygin <antonc27@mail.ru>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */

#import "GameLogViewController.h"

@interface GameLogViewController ()

@end

@implementation GameLogViewController

#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(dismissAction)];
    self.navigationItem.rightBarButtonItem = closeButton;
    [closeButton release];
    
    NSString *debugStr = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:DEBUG_FILE()])
        debugStr = [[NSString alloc] initWithContentsOfFile:DEBUG_FILE() encoding:NSUTF8StringEncoding error:nil];
    else
        debugStr = [[NSString alloc] initWithString:@"Here be log"];
    
    UITextView *logView = [[UITextView alloc] initWithFrame:self.view.frame];
    [logView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
    logView.text = debugStr;
    [debugStr release];
    logView.editable = NO;
    
    [self.view addSubview:logView];
    [logView release];
}

#pragma mark - Actions

- (void)dismissAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Memory warning

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
