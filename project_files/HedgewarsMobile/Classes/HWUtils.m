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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.
 */


#import "HWUtils.h"
#import <sys/types.h>
#import <sys/sysctl.h>
#import <netinet/in.h>
#import <SystemConfiguration/SCNetworkReachability.h>
#import "hwconsts.h"

static NSString *cachedModel = nil;
static NSArray *cachedColors = nil;
static NSMutableArray *activePorts = nil;

static TGameType gameType = gtNone;
static TGameStatus gameStatus = gsNone;

@implementation HWUtils

#pragma mark -
#pragma mark game status and type info
+ (TGameType)gameType {
    return gameType;
}

+ (void)setGameType:(TGameType)type {
    gameType = type;
}

+ (TGameStatus)gameStatus {
    return gameStatus;
}

+ (void)setGameStatus:(TGameStatus)status {
    gameStatus = status;
}

+ (BOOL)isGameLaunched {
    return ((gameStatus == gsLoading) || (gameStatus == gsInGame));
}

+ (BOOL)isGameRunning {
    return (gameStatus == gsInGame);
}

#pragma mark -
#pragma mark Helper Functions with cache
+ (NSString *)modelType {
    if (cachedModel == nil) {
        size_t size;
        // set 'oldp' parameter to NULL to get the size of the data returned so we can allocate appropriate amount of space
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *name = (char *)malloc(sizeof(char) * size);
        // get the platform name
        sysctlbyname("hw.machine", name, &size, NULL, 0);

        cachedModel = [NSString stringWithUTF8String:name];
        free(name);
    }
    return cachedModel;
}

+ (NSArray *)teamColors {
    if (cachedColors == nil) {
        // by default colors are ARGB but we do computation over RGB, hence we have to "& 0x00FFFFFF" before processing
        unsigned int colors[] = HW_TEAMCOLOR_ARRAY;
        NSMutableArray *array = [[NSMutableArray alloc] init];

        int i = 0;
        while(colors[i] != 0)
            [array addObject:[NSNumber numberWithUnsignedInt:(colors[i++] & 0x00FFFFFF)]];

        cachedColors = [NSArray arrayWithArray:array];
    }
    return cachedColors;
}

+ (void)releaseCache {
    cachedModel = nil;
    cachedColors = nil;
    // don't release activePorts here
}

#pragma mark -
#pragma mark Helper Functions without cache
+ (NSInteger)randomPort {
    // set a new feed only at initialization time and forbid connecting to the server port
    if (activePorts == nil) {
        activePorts = [NSMutableArray arrayWithObject:[NSNumber numberWithInt:NETGAME_DEFAULT_PORT]];
    }

    // pick a random number from the free ports list
    NSInteger res = 0;
    do {
        res = (arc4random_uniform(64511)) + 1024;
    } while ([activePorts containsObject:[NSNumber numberWithInteger:res]]);

    // add this number to the forbdding list
    [activePorts addObject:[NSNumber numberWithInteger:res]];
    return res;
}

+ (void)freePort:(NSInteger)port {
    [activePorts removeObject:[NSNumber numberWithInteger:port]];
}

+ (BOOL)isNetworkReachable {
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;

    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;

    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);

    if (!didRetrieveFlags) {
        NSLog(@"Error. Could not recover network reachability flags");
        return NO;
    }

    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;

    NSURL *testURL = [NSURL URLWithString:@"http://www.apple.com/"];
    NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL
                                                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                             timeoutInterval:20.0];
    NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:nil];
    BOOL testResult = testConnection ? YES : NO;

    return ((isReachable && !needsConnection) || nonWiFi) ? testResult : NO;
}

+ (NSString *)languageID
{
    NSString *language = [[NSLocale preferredLanguages] firstObject];
    return [[language componentsSeparatedByString:@"-"] firstObject];
}

/*
+ (UIView *)mainSDLViewInstance {
    SDL_Window *window = HW_getSDLWindow();
    if (window == NULL) {
        SDL_SetError("Window does not exist");
        return nil;
    }
    SDL_WindowData *data = (SDL_WindowData *)window->driverdata;
    SDL_uikitview *view = data != NULL ? data->view : nil;
    return view;
}
*/

+ (NSString *)seed
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *seed = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
    CFRelease(uuid);
    return seed;
}

@end
