//
//  AppDelegate.m
//  Build UCAC3 Catalog
//
//  Created by Peter Polakovic on 04/03/15.
//  Copyright (c) 2015 CloudMakers, s. r. o. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "AppDelegate.h"

#define GROUP @"AstrometryNet"
#define URL   @"http://cdsarc.u-strasbg.fr/ftp/cats/aliases/U/UCAC3/UCAC3/z%03d.bz2"

#define IMIN  1
#define IMAX  360

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet WebView *readme;
@property (weak) IBOutlet NSTextField *status;
@property (weak) IBOutlet NSProgressIndicator *indicator;
@property (weak) IBOutlet NSButton *downloadButton;
@property (weak) IBOutlet NSButton *buildButton;
@end

@implementation AppDelegate {
  NSWorkspace *workspace;
  NSFileManager *fileManager;
  NSString *dataFolder;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSError *error;
  workspace = [NSWorkspace sharedWorkspace];
  fileManager = [NSFileManager defaultManager];
  _readme.drawsBackground = NO;
  _readme.preferences.defaultFontSize = 40;
  _readme.mainFrameURL = @"http://cdsarc.u-strasbg.fr/vizier/ftp/cats/aliases/U/UCAC3/ReadMe";
  dataFolder = [NSString stringWithFormat:@"%@/Library/Application Support/Data", [fileManager containerURLForSecurityApplicationGroupIdentifier:GROUP].path];
  NSLog(@"Group data folder = %@", dataFolder);
  [fileManager createDirectoryAtPath:dataFolder withIntermediateDirectories:YES attributes:nil error:&error];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (void) downloadFinished {
  _status.stringValue = @"Download finished";
  _buildButton.enabled = YES;
  NSLog(@"Download finished");
}

- (void) downloadFile:(int)i {
  _indicator.doubleValue = i;
  NSString *name = [NSString stringWithFormat:@"z%03d.bz2", i];
  NSString *file = [NSString stringWithFormat:@"%@/%@", dataFolder, name];
  NSString *url = [NSString stringWithFormat:URL, i];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
  request.HTTPMethod = @"HEAD";
  [request setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
  [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *resp, NSData *data, NSError *error) {
    long length = [[((NSHTTPURLResponse *)resp).allHeaderFields objectForKey:@"Content-Length"] integerValue];
    _status.stringValue = [NSString stringWithFormat:@"Downloading %@ (%ld bytes)...", name, length];
    if (![fileManager fileExistsAtPath:file] || [[fileManager attributesOfItemAtPath:file error:nil] fileSize] != length) {
      request.HTTPMethod = @"GET";
      [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *resp, NSData *data, NSError *error) {
        [data writeToFile:file atomically:YES];
        NSLog(@"%@ downloaded (%ld bytes)", name, length);
        if (i < IMAX) {
          [self downloadFile:i+1];
        } else {
          [self downloadFinished];
        }
      }];
    } else {
      NSLog(@"%@ found (%ld bytes)", name, length);
      if (i < IMAX) {
        [self downloadFile:i+1];
      } else {
        [self downloadFinished];
      }
    }
  }];
}

- (IBAction)download:(id)sender {
  _indicator.minValue = IMIN;
  _indicator.maxValue = IMAX;
  NSLog(@"Download started");
  [self downloadFile:IMIN];
}

- (IBAction)build:(id)sender {
  
  NSString *logFile = [NSString stringWithFormat:@"%@/build.log", dataFolder];
  [fileManager createFileAtPath: logFile contents: nil attributes: nil];
  NSFileHandle *log = [NSFileHandle fileHandleForWritingAtPath:logFile];
  
  NSTask *task;
  NSArray *files;
  NSMutableArray *selectedFiles;
  NSMutableArray *params;
  
  [_indicator setIndeterminate:YES];
  
  _status.stringValue = @"Cleanup...";
  files = [fileManager directoryContentsAtPath:dataFolder];
  for (NSString *file in files) {
    if ([file hasSuffix:@".fits"]) {
      [workspace performFileOperation:NSWorkspaceRecycleOperation source:dataFolder destination:@"" files:@[file] tag:nil];
    }
  }
  
  _status.stringValue = @"Running ucac3tofits...";
  files = [fileManager directoryContentsAtPath:dataFolder];
  selectedFiles = [NSMutableArray array];
  for (NSString *file in files) {
    if ([file hasPrefix:@"z"] && [file hasSuffix:@".bz2"]) {
      [selectedFiles addObject:file];
    }
  }
  task = [[NSTask alloc] init];
  params = [NSMutableArray arrayWithArray: @[@"-N", @"1"]];
  [params addObjectsFromArray:selectedFiles];
  [task setLaunchPath: [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"ucac3tofits"]];
  [task setCurrentDirectoryPath:dataFolder];
  [task setArguments: params];
  [task setStandardOutput:log];
  [task launch];
//  NSLog(@"ucac3tofits %@", params);
  [task waitUntilExit];
//  [workspace performFileOperation:NSWorkspaceRecycleOperation source:dataFolder destination:@"" files:selectedFiles tag:nil];

  
  _status.stringValue = @"Running hpsplit...";
  files = [fileManager directoryContentsAtPath:dataFolder];
  selectedFiles = [NSMutableArray array];
  for (NSString *file in files) {
    if ([file hasPrefix:@"ucac3_"] && [file hasSuffix:@".fits"]) {
      [selectedFiles addObject:file];
    }
  }
  task = [[NSTask alloc] init];
  params = [NSMutableArray arrayWithArray: @[@"-o", @"split-%02i.fits", @"-n", @"1", @"-m", @"1"]];
  [params addObjectsFromArray:selectedFiles];
  [task setLaunchPath: [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"hpsplit"]];
  [task setCurrentDirectoryPath:dataFolder];
  [task setArguments: params];
  [task setStandardOutput:log];
  [task launch];
  NSLog(@"hpsplit %@", params);
  [task waitUntilExit];
//  [workspace performFileOperation:NSWorkspaceRecycleOperation source:dataFolder destination:@"" files:selectedFiles tag:nil];
  
  NSString *fitscopy = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"fitscopy"];
  files = [fileManager directoryContentsAtPath:dataFolder];
  for (NSString *file in files) {
    if ([file hasPrefix:@"split-"] && [file hasSuffix:@".fits"]) {
      _status.stringValue = [NSString stringWithFormat:@"Running fitscopy on %@...", file];
      NSLog(@"fitscopy \"%@[col RA;DEC;MAG]\" cut-%@", file, file);
      task = [[NSTask alloc] init];
      [task setLaunchPath: fitscopy];
      [task setCurrentDirectoryPath:dataFolder];
      [task setArguments:@[[NSString stringWithFormat:@"%@[col RA;DEC;MAG]", file], [NSString stringWithFormat:@"cut-%@", file]]];
      [task setStandardOutput:log];
      [task launch];
      [task waitUntilExit];
//      [workspace performFileOperation:NSWorkspaceRecycleOperation source:dataFolder destination:@"" files:@[file] tag:nil];
    }
  }
  NSString *buildAstrometryIndex = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"build-astrometry-index"];
  files = [fileManager directoryContentsAtPath:dataFolder];
  time_t rawtime;
  char name[9] = "YYYYmmdd";
  time(&rawtime);
  strftime(name, 9, "%Y%m%d", localtime(&rawtime));
  for (NSString *file in files) {
    if ([file hasPrefix:@"cut-split-"] && [file hasSuffix:@".fits"]) {
      NSString *no = [[file substringFromIndex:10] substringToIndex:2];
      for (int scale = 5; scale <= 7; scale++) {
        _status.stringValue = [NSString stringWithFormat:@"Running build-astrometry-index on %@...", file];
        NSLog(@"build-astrometry-index -i %@ -o index-ucac3-%d-%@.fits -P %d -S MAG -H %@ -s 1 -I %s%02d", file, scale, no, scale, no, name, scale);
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath: buildAstrometryIndex];
        [task setCurrentDirectoryPath:dataFolder];
        [task setArguments:@[@"-i", file, @"-o", [NSString stringWithFormat:@"index-ucac3-%d-%@.fits", scale, no],
                             @"-P", [NSString stringWithFormat:@"%d", scale], @"-S", @"MAG", @"-H", no, @"-s", @"1",
                             @"-I", [NSString stringWithFormat:@"%s%02d", name, scale]]];
        [task setStandardOutput:log];
        [task launch];
        [task waitUntilExit];
      }
//      [workspace performFileOperation:NSWorkspaceRecycleOperation source:dataFolder destination:@"" files:@[file] tag:nil];
    }
  }

  [_indicator setIndeterminate:NO];
  _status.stringValue = @"Done";
}

@end
