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
 * File created on 21/09/2010.
 */


#import "NSStringExtra.h"

@implementation NSString (extra)

-(BOOL) appendToFile:(NSString *)path {
    NSOutputStream* os = [[NSOutputStream alloc] initToFileAtPath:path append:YES];
    NSData *allData = [self dataUsingEncoding:NSUTF8StringEncoding];

    [os open];
    [os write:[allData bytes] maxLength:[allData length]];
    [os close];
    
    [os release];
    return YES;
}

-(BOOL) appendToFile:(NSString *)path usingStream:(NSOutputStream *)os {
    NSData *allData = [self dataUsingEncoding:NSUTF8StringEncoding];
    [os write:[allData bytes] maxLength:[allData length]];
    return YES;
}

// by http://iphonedevelopment.blogspot.com/2010/08/nsstring-appendtofileusingencoding.html
-(BOOL) appendToFile:(NSString *)path usingEncoding:(NSStringEncoding) encoding {
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path]; 
    if (fh == nil)
        return [self writeToFile:path atomically:YES encoding:encoding error:nil];
    
    [fh truncateFileAtOffset:[fh seekToEndOfFile]];
    NSData *encoded = [self dataUsingEncoding:encoding];
    
    if (encoded == nil) 
        return NO;
    
    [fh writeData:encoded];
    return YES;
}

@end
