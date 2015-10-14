/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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


#import "RestoreViewController.h"
#import "GameInterfaceBridge.h"

@interface RestoreViewController ()
@property (retain, nonatomic) IBOutlet UIButton *restoreButton;
@property (retain, nonatomic) IBOutlet UIButton *dismissButton;
@end

@implementation RestoreViewController

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

-(IBAction) buttonReleased:(id) sender {
    UIButton *theButton = (UIButton *)sender;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (theButton.tag != 0) {
        [[AudioManagerController mainManager] playClickSound];
        [GameInterfaceBridge registerCallingController:self.presentingViewController];
        
        // Since iOS 8, the file system layout of app containers has changed.
        // So, we must rely now on saved game filename, not full path.
        NSString *oldSavedGamePath = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedGamePath"];
        NSString *savedGameFile = [oldSavedGamePath lastPathComponent];
        NSString *newSavedGamePath = [NSString stringWithFormat:@"%@%@", SAVES_DIRECTORY(), savedGameFile];
        
        [GameInterfaceBridge startSaveGame:newSavedGamePath];
    } else {
        [[AudioManagerController mainManager] playBackSound];
        [defaults setObject:@"" forKey:@"savedGamePath"];
        [defaults synchronize];
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void) viewDidLoad {
    [super viewDidLoad];
    
    [self.restoreButton applyDarkBlueQuickStyle];
    [self.dismissButton applyDarkBlueQuickStyle];
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    [super viewDidUnload];
}

-(void) dealloc {
    [_restoreButton release];
    [_dismissButton release];
    [super dealloc];
}


@end
