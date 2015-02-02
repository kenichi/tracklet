//
//  NetworkManager.h
//  Tracklet
//
//  Copyright (c) 2015 io.nakamura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Location.h"
#import "Visit.h"

@interface NetworkManager : NSObject

@property (strong, nonatomic) NSURL *baseUrl;

+ (id)sharedManager;

- (void)uploadLocation:(Location *)location;
- (void)uploadVisit:(Visit *)visit;

- (void)uploadLocations:(NSArray *)locations completion:(void (^)(NSError *error))completion;
- (void)uploadVisits:(NSArray *)visits completion:(void (^)(NSError *error))completion;

@end
