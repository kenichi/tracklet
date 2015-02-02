//
//  LocationManager.h
//  Tracklet
//
//  Copyright (c) 2015 io.nakamura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class LocationManager;

@protocol LocationManagerDelegate

@optional
- (void)locationManager:(LocationManager *)locationManager didSaveLocations:(NSArray *)locations;
- (void)locationManager:(LocationManager *)locationManager didSaveVisit:(CLVisit *)visit;

@end

@interface LocationManager : NSObject <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic) BOOL updatingLocations;
@property (nonatomic) BOOL monitoringVisits;
@property (weak, nonatomic) id delegate;

+ (id)sharedManager;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
- (void)startMonitoringVisits;
- (void)stopMonitoringVisits;

@end
