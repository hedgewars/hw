/*
 * Hedgewars-iOS, a Hedgewars port for iOS devices
 * Copyright (c) 2015-2016 Anton Malmygin <antonc27@mail.ru>
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

#import "IniParser.h"

#define COMMENTS_START_CHAR ';'
#define  SECTION_START_CHAR '['

@interface IniParser ()
@property (nonatomic, retain) NSString *iniFilePath;

@property (nonatomic, retain) NSMutableArray *mutableSections;
@property (nonatomic, retain) NSMutableDictionary *currentSection;
@end

@implementation IniParser

#pragma mark - Initilisation

- (instancetype)initWithIniFilePath:(NSString *)iniFilePath {
    self = [super init];
    if (self) {
        _iniFilePath = [iniFilePath copy];
    }
    return self;
}

#pragma mark - Parse sections

- (NSArray *)newParsedSections {
    NSString *iniFileContents = [NSString stringWithContentsOfFile:self.iniFilePath encoding:NSUTF8StringEncoding error:nil];
    
    [self prepareForParsing];
    [iniFileContents enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if (![self isNeedToSkipLine:line]) {
            [self parseLine:line];
        }
    }];
    [self addLastParsedSectionToSections];
    
    return [self copyParsedSections];
}

- (void)prepareForParsing {
    self.mutableSections = [[NSMutableArray alloc] init];
    self.currentSection = nil;
}

- (BOOL)isNeedToSkipLine:(NSString *)line {
    return ([line length] < 1 || [self isLineAComment:line]);
}

- (BOOL)isLineAComment:(NSString *)line {
    return ([line characterAtIndex:0] == COMMENTS_START_CHAR);
}

- (void)parseLine:(NSString *)line {
    if ([self isLineASectionStart:line]) {
        [self addPreviousSectionToSectionsIfNecessary];
        [self createCurrentSection];
    } else {
        [self parseAssignmentForCurrentSectionInLine:line];
    }
}

- (BOOL)isLineASectionStart:(NSString *)line {
    return ([line characterAtIndex:0] == SECTION_START_CHAR);
}

- (void)addPreviousSectionToSectionsIfNecessary {
    if (self.currentSection != nil) {
        [self.mutableSections addObject:self.currentSection];
        [self.currentSection release];
    }
}

- (void)createCurrentSection {
    self.currentSection = [[NSMutableDictionary alloc] init];
}

- (void)parseAssignmentForCurrentSectionInLine:(NSString *)line {
    NSArray *components = [line componentsSeparatedByString:@"="];
    if (components.count > 1) {
        NSString *key = components[0];
        NSString *value = components[1];
        [self.currentSection setObject:value forKey:key];
    }
}

- (void)addLastParsedSectionToSections {
    [self addPreviousSectionToSectionsIfNecessary];
}

- (NSArray *)copyParsedSections {
    return [self.mutableSections copy];
}

#pragma mark - Dealloc

- (void)dealloc {
    [_iniFilePath release];
    [_mutableSections release];
    [_currentSection release];
    [super dealloc];
}

@end
