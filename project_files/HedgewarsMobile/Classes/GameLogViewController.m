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

#ifdef DEBUG
#import <MessageUI/MFMailComposeViewController.h>
#endif

@interface GameLogViewController ()
#ifdef DEBUG
<MFMailComposeViewControllerDelegate>
#endif

@end

@implementation GameLogViewController

#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Last game log";
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(dismissAction)];
    self.navigationItem.rightBarButtonItem = closeButton;
    [closeButton release];
    
#ifdef DEBUG
    if ([self allowSendLogByEmail])
    {
        UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(sendLogByEmailAction)];
        self.navigationItem.leftBarButtonItem = sendButton;
        [sendButton release];
    }
#endif
    
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

#pragma mark - Parameters

#ifdef DEBUG
- (BOOL)allowSendLogByEmail
{
    return ([MFMailComposeViewController canSendMail] && [[NSFileManager defaultManager] fileExistsAtPath:DEBUG_FILE()]);
}
#endif

#pragma mark - Actions

#ifdef DEBUG
- (void)sendLogByEmailAction
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker setSubject:@"Log file of iHedgewars game"];
    
    // Attach a log file to the email
    NSData *logData = [NSData dataWithContentsOfFile:DEBUG_FILE()];
    [picker addAttachmentData:logData mimeType:@"text/plain" fileName:@"game0.log"];
    
    // Fill out the email body text
    NSString *emailBody = @"Add here description of a problem/log";
    [picker setMessageBody:emailBody isHTML:NO];
    
    [self presentViewController:picker animated:YES completion:nil];
    [picker release];
}
#endif

- (void)dismissAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MailCompose delegate

#ifdef DEBUG
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"MailComposeResult: canceled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"MailComposeResult: saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"MailComposeResult: sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"MailComposeResult: failed");
            break;
        default:
            NSLog(@"MailComposeResult: not sent");
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
#endif

#pragma mark - Memory warning

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
