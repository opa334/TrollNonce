@import Foundation;

extern NSString* helperPath(void);
extern void printMultilineNSString(NSString* stringToPrint);
extern int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);