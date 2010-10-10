/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2009-2010 Vittorio Giovara <vittorio.giovara@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * File created on 03/10/2010.
 */


#import "AmmoMenuViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CommodityFunctions.h"
#import "UIImageExtra.h"
#import "PascalImports.h"

@implementation AmmoMenuViewController
@synthesize weaponsImage, buttonsArray, isVisible;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    return rotationManager(interfaceOrientation);
}

#pragma mark -
#pragma mark view handling
-(void) viewDidLoad {    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAmmoVisuals)
                                                 name:@"updateAmmoVisuals"
                                               object:nil];
     
    self.view.frame = CGRectMake(0, 0, 480, 320);
    self.view.backgroundColor = [UIColor blackColor];
    self.view.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.view.layer.borderWidth = 1.3f;
    [self.view.layer setCornerRadius:10];
    [self.view.layer setMasksToBounds:YES];

    self.isVisible = NO;
    delay = (uint8_t *) calloc(HW_getNumberOfWeapons(), sizeof(uint8_t));
    HW_getAmmoDelays(delay);

    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated {
    [self updateAmmoVisuals];
    [super viewWillAppear:animated];
}

-(void) appearInView:(UIView *)container {
    [self viewWillAppear:YES];
    [container addSubview:self.view];
    self.view.center = CGPointMake(container.center.y, container.center.x);
    self.isVisible = YES;
}

-(void) disappear {
    if (self.isVisible)
        [self.view removeFromSuperview];
    self.isVisible = NO;
}

#pragma mark -
#pragma mark drawing
-(void) loadAmmoStuff:(id) object {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *str = [NSString stringWithFormat:@"%@/AmmoMenu/Ammos.png",GRAPHICS_DIRECTORY()];
    UIImage *ammoStoreImage = [[UIImage alloc] initWithContentsOfFile:str];
    [self performSelectorOnMainThread:@selector(setWeaponsImage:) withObject:ammoStoreImage waitUntilDone:NO];
    [ammoStoreImage release];

    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:HW_getNumberOfWeapons()];
    for (int i = 0; i < HW_getNumberOfWeapons(); i++) {
        int x_dst = 10+(i%10)*44;
        int y_dst = 10+(i/10)*44;
        
        if (i / 10 % 2 != 0)
            x_dst += 20;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(x_dst, y_dst, 40, 40);
        button.tag = i;
        button.layer.borderWidth = 1;
        button.layer.borderColor = [UICOLOR_HW_YELLOW_TEXT CGColor];
        [button.layer setCornerRadius:6];
        [button.layer setMasksToBounds:YES];
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitleColor:UICOLOR_HW_YELLOW_TEXT forState:UIControlStateNormal];
        button.titleLabel.backgroundColor = [UIColor blackColor];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
        [button.titleLabel.layer setCornerRadius:3];
        [button.titleLabel.layer setMasksToBounds:YES];
        button.titleLabel.layer.borderColor = [[UIColor whiteColor] CGColor];
        button.titleLabel.layer.borderWidth = 1;
        [self.view addSubview:button];
        [array addObject:button];
    }
    [self performSelectorOnMainThread:@selector(setButtonsArray:) withObject:array waitUntilDone:NO];
    [array release];
    
    [self performSelectorOnMainThread:@selector(updateAmmoVisuals) withObject:nil waitUntilDone:NO];
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)object;
    [spinner stopAnimating];
    [pool drain];
}

-(void) updateAmmoVisuals {
    if (self.buttonsArray == nil || self.weaponsImage == nil) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.hidesWhenStopped = YES;
        spinner.center = self.view.center;
        [spinner startAnimating];
        [self.view addSubview:spinner];
        [NSThread detachNewThreadSelector:@selector(loadAmmoStuff:) toTarget:self withObject:spinner];
        [spinner release];
        return;
    }
    
    [NSThread detachNewThreadSelector:@selector(drawingThread) toTarget:self withObject:nil];
}

-(void) drawingThread {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int *loadout = (int *)calloc(HW_getNumberOfWeapons(), sizeof(int));
    int res = HW_getAmmoCounts(loadout);
    int turns = HW_getTurnsForCurrentTeam();
    
    if (res == 0) {
        self.view.userInteractionEnabled = YES;
        
        for (int i = 0; i < HW_getNumberOfWeapons(); i++) {
            UIButton *button = [self.buttonsArray objectAtIndex:i];
            if (loadout[i] > 0) {
                if (delay[i]-turns >= 0) {
                    button.layer.borderColor = [[UIColor lightGrayColor] CGColor];
                    [button setTitle:[NSString stringWithFormat:@" %d ",delay[i]-turns+1] forState:UIControlStateNormal];
                    if (button.currentBackgroundImage == nil) {
                        int x_src = ((i*32)/(int)self.weaponsImage.size.height)*32;
                        int y_src = (i*32)%(int)self.weaponsImage.size.height;
                        UIImage *img = [self.weaponsImage cutAt:CGRectMake(x_src, y_src, 32, 32)];
                        [button setBackgroundImage:[img convertToGrayScale] forState:UIControlStateNormal];
                        button.imageView.tag = 10000;
                    }
                } else {
                    button.layer.borderColor = [UICOLOR_HW_YELLOW_TEXT CGColor];
                    [button setTitle:@"" forState:UIControlStateNormal];
                    if (button.currentBackgroundImage == nil || button.imageView.tag == 10000) {
                        int x_src = ((i*32)/(int)self.weaponsImage.size.height)*32;
                        int y_src = (i*32)%(int)self.weaponsImage.size.height;
                        UIImage *img = [self.weaponsImage cutAt:CGRectMake(x_src, y_src, 32, 32)];
                        [button setBackgroundImage:img forState:UIControlStateNormal];
                        button.imageView.tag = 0;
                    }
                }
                button.enabled = YES;
            } else {
                if (button.enabled == YES)
                    [button setBackgroundImage:nil forState:UIControlStateNormal];
                button.layer.borderColor = [[UIColor darkGrayColor] CGColor];
                button.enabled = NO;
            }
            
        }
    } else {
        self.view.userInteractionEnabled = NO;
    }

    free(loadout);
    loadout = NULL;
    [pool drain];
}

#pragma mark -
#pragma mark user interaction
-(void) buttonPressed:(id) sender {
    UIButton *theButton = (UIButton *)sender;
    HW_setWeapon(theButton.tag);
    playSound(@"clickSound");
    [self disappear];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /*
    NSSet *allTouches = [event allTouches];

    if ([touches count] == 1) {
        self.view.layer.borderWidth = 3.5;
        startingPoint = [[[allTouches allObjects] objectAtIndex:0] locationInView:self.view];
    }
    */
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //self.view.layer.borderWidth = 1.3;
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    /*
    NSSet *allTouches = [event allTouches];

    if ([touches count] == 1) {
        CGPoint touchedPoint = [[[allTouches allObjects] objectAtIndex:0] locationInView:self.view];
        CGFloat deltaX = touchedPoint.x - startingPoint.x;
        CGFloat deltaY = touchedPoint.y - startingPoint.y;

        //startingPoint = touchedPoint;
        self.view.frame = CGRectMake(self.view.frame.origin.x + deltaX, self.view.frame.origin.y + deltaY,
                                     self.view.frame.size.width, self.view.frame.size.height);
    }
    */
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    //[self touchesEnded:touches withEvent:event];
}

#pragma mark -
#pragma mark memory
-(void) didReceiveMemoryWarning {
    self.weaponsImage = nil;
    self.buttonsArray = nil;
    MSG_MEMCLEAN();
    [super didReceiveMemoryWarning];
}

-(void) viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.weaponsImage = nil;
    self.buttonsArray = nil;
    free(delay);
    delay = NULL;
    MSG_DIDUNLOAD();
    [super viewDidUnload];
}

-(void) dealloc {
    [weaponsImage release];
    [buttonsArray release];
    [super dealloc];
}

@end

void updateVisualsNewTurn (void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateAmmoVisuals" object:nil];
}
