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


-(void) viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateVisuals:)
                                                 name:@"updateAmmoVisuals"
                                               object:nil];
     
    self.view.frame = CGRectMake(0, 0, 480, 320);
    self.view.backgroundColor = [UIColor blackColor];
    self.view.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.view.layer.borderWidth = 1.3f;
    [self.view.layer setCornerRadius:10];
    [self.view.layer setMasksToBounds:YES];

    self.isVisible = NO;
    delay = HW_getAmmoDelays();

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.hidesWhenStopped = YES;
    spinner.center = self.view.center;
    [spinner startAnimating];
    [self.view addSubview:spinner];
    if (self.buttonsArray == nil)
        [NSThread detachNewThreadSelector:@selector(loadAmmoStuff:) toTarget:self withObject:spinner];
    [spinner release];
}

-(void) viewWillAppear:(BOOL)animated {
    if (self.buttonsArray != nil)
        [self updateVisuals:nil];
    [super viewWillAppear:animated];
}

-(void) appearInView:(UIView *)container {
    [self viewWillAppear:YES];
    [container addSubview:self.view];
    self.view.center = CGPointMake(container.center.y, container.center.x);
    self.isVisible = YES;
    [self viewDidAppear:YES];                 
}

-(void) disappear {

    [self.view removeFromSuperview];
    self.isVisible = NO;
}

-(void) loadAmmoStuff:(id) object {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)object;

    NSString *str = [NSString stringWithFormat:@"%@/AmmoMenu/Ammos.png",GRAPHICS_DIRECTORY()];
    UIImage *ammoStoreImage = [[UIImage alloc] initWithContentsOfFile:str];
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:HW_getNumberOfWeapons()];
    for (int i = 0; i < HW_getNumberOfWeapons(); i++) {
        int x_src = ((i*32)/(int)ammoStoreImage.size.height)*32;
        int y_src = (i*32)%(int)ammoStoreImage.size.height;
        int x_dst = 10+(i%10)*44;
        int y_dst = 10+(i/10)*44;
        
        if (i / 10 % 2 != 0)
            x_dst += 20;
        UIImage *img = [ammoStoreImage cutAt:CGRectMake(x_src, y_src, 32, 32)];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(x_dst, y_dst, 40, 40);
        button.tag = i;
        button.layer.borderWidth = 1;
        button.layer.borderColor = [UICOLOR_HW_YELLOW_TEXT CGColor];
        [button.layer setCornerRadius:6];
        [button.layer setMasksToBounds:YES];
        [button setBackgroundImage:img forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitleColor:UICOLOR_HW_YELLOW_TEXT forState:UIControlStateNormal];
        button.titleLabel.backgroundColor = [UIColor blackColor];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        [button.titleLabel.layer setCornerRadius:3];
        [button.titleLabel.layer setMasksToBounds:YES];
        button.titleLabel.layer.borderColor = [[UIColor whiteColor] CGColor];
        button.titleLabel.layer.borderWidth = 1;
        [self.view addSubview:button];
        [array addObject:button];
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:array,@"array",ammoStoreImage,@"image",spinner,@"spinner",nil];
    [array release];
    [ammoStoreImage release];

    [self performSelectorOnMainThread:@selector(ready:) withObject:dict waitUntilDone:NO];
    
    [pool drain];
}

-(void) ready:(id) object {
    NSDictionary *dict = (NSDictionary *)object;
    [[dict objectForKey:@"spinner"] stopAnimating];
    self.weaponsImage = [dict objectForKey:@"image"];
    self.buttonsArray = [dict objectForKey:@"array"];
    [self updateVisuals:nil];
}

-(void) updateVisuals:(NSNotification *) object {
    unsigned char *loadout = HW_getAmmoCounts();
    int turns = HW_getTurnsForCurrentTeam();

    if (self.buttonsArray == nil) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.hidesWhenStopped = YES;
        spinner.center = self.view.center;
        [spinner startAnimating];
        [self.view addSubview:spinner];
        [NSThread detachNewThreadSelector:@selector(loadAmmoStuff:) toTarget:self withObject:spinner];
        [spinner release];
    }
    
    if (loadout == NULL) {
        self.view.userInteractionEnabled = NO;
        return;
    } else
        self.view.userInteractionEnabled = YES;

    for (int i = 0; i < HW_getNumberOfWeapons(); i++) {
        UIButton *button = [self.buttonsArray objectAtIndex:i];
        if (loadout[i] > 0) {
            /*if (button.enabled == NO) {
                int x_src = ((i*32)/(int)self.weaponsImage.size.height)*32;
                int y_src = (i*32)%(int)self.weaponsImage.size.height;
                UIImage *img = [self.weaponsImage cutAt:CGRectMake(x_src, y_src, 32, 32)];
                [button setBackgroundImage:img forState:UIControlStateNormal];
            }*/
            button.enabled = YES;
            button.layer.borderColor = [UICOLOR_HW_YELLOW_TEXT CGColor];
        } else {
            /*if (button.enabled == YES) {
                int x_src = ((i*32)/(int)self.weaponsImage.size.height)*32;
                int y_src = (i*32)%(int)self.weaponsImage.size.height;
                UIImage *img = [self.weaponsImage cutAt:CGRectMake(x_src, y_src, 32, 32)];
                [button setBackgroundImage:img forState:UIControlStateNormal];
            }*/
            button.enabled = NO;
            button.layer.borderColor = [[UIColor darkGrayColor] CGColor];
            //NSLog(@"disabled: %d",button.tag);
        }
        
        if (button.enabled == YES) {
            if (delay[i]-turns >= 0) {
            //    NSLog(@"delayed(%d) %d",delay[i], button.tag);
                button.layer.borderColor = [[UIColor lightGrayColor] CGColor];
                [button setTitle:[NSString stringWithFormat:@" %d ",delay[i]-turns+1] forState:UIControlStateNormal];
            } else {
             //   NSLog(@"enabled %d",button.tag);
                button.layer.borderColor = [UICOLOR_HW_YELLOW_TEXT CGColor];
                [button setTitle:@"" forState:UIControlStateNormal];
            }
        }
    }
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
