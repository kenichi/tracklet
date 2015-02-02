//
//  LocationManager.m
//  Tracklet
//
//  Copyright (c) 2015 io.nakamura. All rights reserved.
//

#import "LocationManager.h"
#import "DataManager.h"

@implementation LocationManager

+ (id)sharedManager {
    static LocationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (id)init {
    if (self = [super init]) {
        
        self.updatingLocations = NO;
        self.monitoringVisits = NO;
        
        [self configureLocationManager];
        [self enforceLocationAuthorization];
        
    }
    return self;
}

#pragma mark -

- (void)startUpdatingLocation {
    NSLog(@"starting location updates.");
    [self.locationManager startUpdatingLocation];
    self.updatingLocations = YES;
}

- (void)stopUpdatingLocation {
    NSLog(@"stopping location updates.");
    [self.locationManager stopUpdatingLocation];
    self.updatingLocations = NO;
}

- (void)startMonitoringVisits {
    NSLog(@"starting visit monitoring.");
    [self.locationManager startMonitoringVisits];
    self.monitoringVisits = YES;
}

- (void)stopMonitoringVisits {
    NSLog(@"stopping visit monitoring.");
    [self.locationManager stopMonitoringVisits];
    self.monitoringVisits = NO;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    [[DataManager sharedManager] insertVisit:visit];
    
    if (self.delegate != nil) {
        if ([self.delegate respondsToSelector:@selector(locationManager:didSaveVisit:)]) {
            [self.delegate locationManager:self didSaveVisit:visit];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    DataManager *dataManager = [DataManager sharedManager];
    for (CLLocation *l in locations) {
        [dataManager insertLocation:l];
    }
    
    if (self.delegate != nil) {
        if ([self.delegate respondsToSelector:@selector(locationManager:didSaveLocations:)]) {
            [self.delegate locationManager:self didSaveLocations:locations];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    self.updatingLocations = NO;
    self.monitoringVisits = NO;
    NSLog(@"error! %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            NSLog(@"authorized for always!");
            break;
        default:
            NSLog(@"*NOT* authorized for always!");
            break;
    }
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"location updates paused!");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"location updates resumed!");
}

#pragma mark -

- (void)configureLocationManager {
    self.locationManager = [CLLocationManager new];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    self.locationManager.distanceFilter = 25;
    self.locationManager.delegate = self;
}

- (void)enforceLocationAuthorization {
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusAuthorizedAlways:
            // NSLog(@"always");
            break;
            
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"not determined");
            [self.locationManager requestAlwaysAuthorization];
            break;
            
        default:
            switch ([CLLocationManager authorizationStatus]) {
                case kCLAuthorizationStatusAuthorizedWhenInUse:
                    NSLog(@"when in use");
                    break;
                    
                case kCLAuthorizationStatusRestricted:
                    NSLog(@"restricted");
                    break;
                    
                case kCLAuthorizationStatusDenied:
                    NSLog(@"denied");
                    break;
                    
                default:
                    break;
            }
            break;
            
    }
}

@end
