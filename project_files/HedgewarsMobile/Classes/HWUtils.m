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
 * File created on 01/10/2011.
 */


#import "HWUtils.h"
#import <sys/types.h>
#import <sys/sysctl.h>
#import "hwconsts.h"

static NSString *cachedModel = nil;
static NSArray *cachedColors = nil;

@implementation HWUtils

+(NSString *)modelType {
    if (cachedModel == nil) {
        size_t size;
        // set 'oldp' parameter to NULL to get the size of the data returned so we can allocate appropriate amount of space
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *name = (char *)malloc(sizeof(char) * size);
        // get the platform name
        sysctlbyname("hw.machine", name, &size, NULL, 0);

        cachedModel = [[NSString stringWithUTF8String:name] retain];
        free(name);
        DLog(@"Cache now contains: %@",cachedModel);
    }
    return cachedModel;
}

+(NSArray *)teamColors {
    if (cachedColors == nil) {
        // by default colors are ARGB but we do computation over RGB, hence we have to "& 0x00FFFFFF" before processing
        unsigned int colors[] = HW_TEAMCOLOR_ARRAY;
        NSMutableArray *array = [[NSMutableArray alloc] init];

        int i = 0;
        while(colors[i] != 0)
            [array addObject:[NSNumber numberWithUnsignedInt:(colors[i++] & 0x00FFFFFF)]];

        cachedColors = [[NSArray arrayWithArray:array] retain];
        [array release];
    }
    return cachedColors;
}

+(void) releaseCache {
    releaseAndNil(cachedModel);
    releaseAndNil(cachedColors);
}

@end
