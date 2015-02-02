//
//  Location.h
//  Tracklet
//
//  Copyright (c) 2015 io.nakamura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Upload;

@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * horizontalAccuracy;
@property (nonatomic, retain) NSNumber * altitude;
@property (nonatomic, retain) NSNumber * course;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * speed;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * verticalAccuracy;
@property (nonatomic, retain) Upload *upload;

@end
