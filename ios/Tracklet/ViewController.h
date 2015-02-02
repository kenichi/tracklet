//
//  ViewController.h
//  Tracklet
//
//  Copyright (c) 2014 io.nakamura. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (void)updateLocationsToUploadCount;
- (void)updateLocationsUploadedCount;
- (void)updateVisitsToUploadCount;
- (void)updateVisitsUploadedCount;

@end