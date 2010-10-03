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
@synthesize imagesArray;;


-(void) viewDidLoad {
    [super viewDidLoad];
    self.view.frame = CGRectMake(0, 0, 480, 320);
    self.view.backgroundColor = [UIColor blackColor];
    [self.view.layer setCornerRadius:10];
    [self.view.layer setMasksToBounds:YES];

    NSString *str = [NSString stringWithFormat:@"%@/AmmoMenu/Ammos.png",GRAPHICS_DIRECTORY()];
    UIImage *ammoStoreImage = [[UIImage alloc] initWithContentsOfFile:str];
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:CURRENT_AMMOSIZE];
    for (int i = 0; i < CURRENT_AMMOSIZE; i++) {
        int x_src = ((i*32)/(int)ammoStoreImage.size.height)*32;
        int y_src = (i*32)%(int)ammoStoreImage.size.height;
        int x_dst = 10+(i%10)*44;
        int y_dst = 10+(i/10)*44;
        
        if (i / 10 % 2 != 0)
            x_dst += 20;
        UIImage *img = [ammoStoreImage cutAt:CGRectMake(x_src, y_src, 32, 32)];
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(x_dst, y_dst, 40, 40)];
        button.tag = i+1;
        button.layer.borderWidth = 1;
        button.layer.borderColor = [UICOLOR_HW_YELLOW_TEXT CGColor];
        [button.layer setCornerRadius:6];
        [button.layer setMasksToBounds:YES];
        [button setImage:img forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        [array addObject:button];
        [button release];
    }
    self.imagesArray = array;
    [array release];
    [ammoStoreImage release];

}

-(void) buttonPressed:(id) sender {
    UIButton *theButton = (UIButton *)sender;
    HW_setWeapon(theButton.tag);
}

-(void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

-(void) viewDidUnload {
    [super viewDidUnload];
    self.imagesArray = nil;
}

-(void) dealloc {
    [imagesArray release];
    [super dealloc];
}


@end
