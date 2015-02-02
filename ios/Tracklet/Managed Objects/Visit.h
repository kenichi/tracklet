//
//  Visit.h
//  Tracklet
//
//  Copyright (c) 2015 io.nakamura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Upload;

@interface Visit : NSManagedObject

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * horizontalAccuracy;
@property (nonatomic, retain) NSDate * arrivalDate;
@property (nonatomic, retain) NSDate * departureDate;
@property (nonatomic, retain) Upload *upload;

@end
