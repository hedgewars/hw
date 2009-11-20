#import <UIKit/UIKit.h>

const char* get_documents_path() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex: 0];
    const char* path = [documentsDirectory UTF8String];
    return path;
}
