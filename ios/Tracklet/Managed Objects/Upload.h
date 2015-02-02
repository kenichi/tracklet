//
//  Upload.h
//  Tracklet
//
//  Copyright (c) 2015 io.nakamura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location, Visit;

@interface Upload : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) Location *location;
@property (nonatomic, retain) Visit *visit;

@end
